//! 文件存储服务（含去重、配额检查、存储编排）

use std::path::{Path, PathBuf};
use std::sync::Arc;

use chrono::Utc;
use sqlx::PgPool;
use thiserror::Error;
use uuid::Uuid;

use crate::backend::StorageBackend;
use crate::backend::local_fs::LocalFs;
use crate::image::ImageProcessor;
use crate::model::*;
use crate::repository::StorageRepo;

/// 存储错误类型
#[derive(Debug, Error)]
pub enum StorageError {
    #[error("文件类型不支持: {0}")]
    UnsupportedType(String),

    #[error("文件过大: {size} bytes, 最大允许 {max} bytes")]
    FileTooLarge { size: u64, max: u64 },

    #[error("配额不足")]
    QuotaExceeded { used_bytes: i64, quota_bytes: i64 },

    #[error("IO 错误: {0}")]
    Io(#[from] std::io::Error),

    #[error("图片处理错误: {0}")]
    Image(#[from] crate::image::ImageError),

    #[error("数据库错误: {0}")]
    Db(#[from] sqlx::Error),
}

/// 前端提供的视频元数据
#[derive(Debug, Clone)]
pub struct VideoUploadMetadata {
    pub duration_ms: u64,
    pub width: u32,
    pub height: u32,
}

/// 存储服务配置
#[derive(Debug, Clone)]
pub struct StorageConfig {
    pub base_path: PathBuf,
    pub url_prefix: String,
    pub max_image_size: u64,
    pub max_video_size: u64,
    pub max_file_size: u64,
    pub thumbnail_max_size: u32,
    pub thumbnail_quality: u8,
}

impl Default for StorageConfig {
    fn default() -> Self {
        Self {
            base_path: PathBuf::from("uploads"),
            url_prefix: "/uploads".to_string(),
            max_image_size: 10 * 1024 * 1024,
            max_video_size: 50 * 1024 * 1024,
            max_file_size: 50 * 1024 * 1024,
            thumbnail_max_size: 400,
            thumbnail_quality: 80,
        }
    }
}

impl StorageConfig {
    pub fn from_env() -> Self {
        let mut config = Self::default();
        if let Ok(v) = std::env::var("UPLOAD_BASE_PATH") {
            config.base_path = PathBuf::from(v);
        }
        if let Ok(v) = std::env::var("UPLOAD_MAX_IMAGE_SIZE") && let Ok(n) = v.parse() {
            config.max_image_size = n;
        }
        if let Ok(v) = std::env::var("UPLOAD_MAX_VIDEO_SIZE") && let Ok(n) = v.parse() {
            config.max_video_size = n;
        }
        if let Ok(v) = std::env::var("UPLOAD_MAX_FILE_SIZE") && let Ok(n) = v.parse() {
            config.max_file_size = n;
        }
        config
    }
}

/// 文件存储服务
pub struct StorageService<B: StorageBackend = LocalFs> {
    backend: B,
    image_processor: ImageProcessor,
    config: StorageConfig,
    db: PgPool,
    /// 配额变更回调（user_id, used_bytes, quota_bytes）
    on_quota_changed: Option<Arc<dyn Fn(i64, i64, i64) + Send + Sync>>,
}

impl<B: StorageBackend> StorageService<B> {
    pub fn new(backend: B, config: StorageConfig, db: PgPool) -> Self {
        let image_processor = ImageProcessor::new(
            config.thumbnail_max_size,
            config.thumbnail_quality,
        );
        Self { backend, image_processor, config, db, on_quota_changed: None }
    }

    /// 设置配额变更回调
    pub fn set_on_quota_changed(&mut self, callback: Arc<dyn Fn(i64, i64, i64) + Send + Sync>) {
        self.on_quota_changed = Some(callback);
    }

    /// 触发配额变更通知
    fn notify_quota_changed(&self, user_id: i64, used_bytes: i64, quota_bytes: i64) {
        if let Some(ref cb) = self.on_quota_changed {
            cb(user_id, used_bytes, quota_bytes);
        }
    }

    pub fn max_video_size(&self) -> u64 {
        self.config.max_video_size
    }

    pub fn max_file_size(&self) -> u64 {
        self.config.max_file_size
    }

    pub fn db(&self) -> &PgPool {
        &self.db
    }

    pub fn url_prefix(&self) -> &str {
        &self.config.url_prefix
    }

    /// 查询文件是否已存在（秒传检查，不修改 ref_count）
    pub async fn check_file_exists(&self, hash: &str) -> Result<Option<FileObject>, StorageError> {
        let existing = StorageRepo::find_by_hash(&self.db, hash).await?;
        Ok(existing)
    }

    /// 仅检查配额是否充足（不扣减，用于预检）
    pub async fn check_quota_only(&self, user_id: i64, file_size: i64) -> Result<(), StorageError> {
        self.check_quota(user_id, file_size).await?;
        Ok(())
    }

    /// 检查文件是否已存在（去重）
    async fn check_dedup(&self, hash: &str) -> Result<Option<FileObject>, StorageError> {
        let existing = StorageRepo::find_by_hash(&self.db, hash).await?;
        if let Some(ref file) = existing {
            StorageRepo::increment_ref_count(&self.db, file.id).await?;
        }
        Ok(existing)
    }

    /// 检查用户配额是否充足，返回当前配额信息
    async fn check_quota(&self, user_id: i64, file_size: i64) -> Result<UserStorageQuota, StorageError> {
        let quota = StorageRepo::get_quota(&self.db, user_id).await?
            .unwrap_or(UserStorageQuota {
                user_id,
                used_bytes: 0,
                quota_bytes: 104857600,
                updated_at: Utc::now(),
            });
        if quota.used_bytes + file_size > quota.quota_bytes {
            return Err(StorageError::QuotaExceeded {
                used_bytes: quota.used_bytes,
                quota_bytes: quota.quota_bytes,
            });
        }
        Ok(quota)
    }

    /// 上传图片（含去重 + 配额检查）
    pub async fn upload_image(
        &self,
        data: &[u8],
        filename: &str,
        hash: &str,
        user_id: i64,
    ) -> Result<ImageUploadResponse, StorageError> {
        // 去重检查
        if let Some(file) = self.check_dedup(hash).await? {
            return Ok(ImageUploadResponse {
                file_id: file.id,
                original_url: format!("{}/{}", self.config.url_prefix, file.storage_path),
                thumbnail_url: file.thumb_path
                    .map(|p| format!("{}/{}", self.config.url_prefix, p))
                    .unwrap_or_default(),
                width: file.width.unwrap_or(0) as u32,
                height: file.height.unwrap_or(0) as u32,
                size: file.size as u64,
                format: file.mime_type.split('/').last().unwrap_or("jpg").to_string(),
                is_dedup: true,
            });
        }

        // 校验格式和大小
        let size = data.len() as u64;
        if size > self.config.max_image_size {
            return Err(StorageError::FileTooLarge { size, max: self.config.max_image_size });
        }

        let ext = Path::new(filename)
            .extension()
            .and_then(|e| e.to_str())
            .unwrap_or("jpg")
            .to_lowercase();

        let format = match ext.as_str() {
            "jpg" | "jpeg" => "jpg",
            "png" => "png",
            "gif" => "gif",
            "webp" => "webp",
            _ => return Err(StorageError::UnsupportedType(ext)),
        };

        // 配额检查
        let quota = self.check_quota(user_id, size as i64).await?;

        // 生成路径
        let date_path = Utc::now().format("%Y/%m").to_string();
        let file_id = Uuid::new_v4();
        let original_rel = format!("original/{}/{}.{}", date_path, file_id, ext);
        let thumb_rel = format!("thumb/{}/{}.webp", date_path, file_id);

        // 处理图片：获取宽高 + 生成缩略图
        let (width, height, thumb_data) = self.image_processor.process(data)?;

        // 写入存储
        self.backend.put(&original_rel, data).await?;
        self.backend.put(&thumb_rel, &thumb_data).await?;

        // 写入数据库
        let mime_type = format!("image/{}", format);
        let original_name = truncate_filename(filename, 255);
        let file_obj = StorageRepo::insert_file_object(
            &self.db, hash, &original_rel, size as i64,
            &mime_type, "image",
            Some(width as i32), Some(height as i32), None,
            Some(&thumb_rel), Some(&original_name), user_id,
        ).await?;

        // 扣减配额
        StorageRepo::update_quota_used(&self.db, user_id, size as i64).await?;
        self.notify_quota_changed(user_id, quota.used_bytes + size as i64, quota.quota_bytes);

        Ok(ImageUploadResponse {
            file_id: file_obj.id,
            original_url: format!("{}/{}", self.config.url_prefix, original_rel),
            thumbnail_url: format!("{}/{}", self.config.url_prefix, thumb_rel),
            width,
            height,
            size,
            format: format.to_string(),
            is_dedup: false,
        })
    }

    /// 上传视频（含去重 + 配额检查）
    pub async fn upload_video(
        &self,
        video_data: &[u8],
        video_filename: &str,
        thumb_data: &[u8],
        hash: &str,
        user_id: i64,
        metadata: VideoUploadMetadata,
    ) -> Result<VideoUploadResponse, StorageError> {
        // 去重检查
        if let Some(file) = self.check_dedup(hash).await? {
            return Ok(VideoUploadResponse {
                file_id: file.id,
                video_url: format!("{}/{}", self.config.url_prefix, file.storage_path),
                thumbnail_url: file.thumb_path
                    .map(|p| format!("{}/{}", self.config.url_prefix, p))
                    .unwrap_or_default(),
                duration_ms: file.duration_ms.unwrap_or(0) as u64,
                width: file.width.unwrap_or(0) as u32,
                height: file.height.unwrap_or(0) as u32,
                file_size: file.size as u64,
                is_dedup: true,
            });
        }

        // 校验格式和大小
        let file_size = video_data.len() as u64;
        if file_size > self.config.max_video_size {
            return Err(StorageError::FileTooLarge { size: file_size, max: self.config.max_video_size });
        }

        let ext = Path::new(video_filename)
            .extension()
            .and_then(|e| e.to_str())
            .unwrap_or("")
            .to_lowercase();

        match ext.as_str() {
            "mp4" | "mov" | "avi" => {}
            _ => return Err(StorageError::UnsupportedType(ext)),
        }

        // 配额检查
        let quota = self.check_quota(user_id, file_size as i64).await?;

        // 生成路径
        let date_path = Utc::now().format("%Y/%m").to_string();
        let file_uuid = Uuid::new_v4();
        let video_rel = format!("video/{}/{}.{}", date_path, file_uuid, ext);
        let thumb_rel = format!("thumb/{}/{}.jpg", date_path, file_uuid);

        // 写入存储
        self.backend.put(&video_rel, video_data).await?;
        self.backend.put(&thumb_rel, thumb_data).await?;

        // 写入数据库
        let mime_type = format!("video/{}", ext);
        let original_name = truncate_filename(video_filename, 255);
        let file_obj = StorageRepo::insert_file_object(
            &self.db, hash, &video_rel, file_size as i64,
            &mime_type, "video",
            Some(metadata.width as i32), Some(metadata.height as i32),
            Some(metadata.duration_ms as i64),
            Some(&thumb_rel), Some(&original_name), user_id,
        ).await?;

        // 扣减配额
        StorageRepo::update_quota_used(&self.db, user_id, file_size as i64).await?;
        self.notify_quota_changed(user_id, quota.used_bytes + file_size as i64, quota.quota_bytes);

        Ok(VideoUploadResponse {
            file_id: file_obj.id,
            video_url: format!("{}/{}", self.config.url_prefix, video_rel),
            thumbnail_url: format!("{}/{}", self.config.url_prefix, thumb_rel),
            duration_ms: metadata.duration_ms,
            width: metadata.width,
            height: metadata.height,
            file_size,
            is_dedup: false,
        })
    }

    /// 上传文件（含去重 + 配额检查）
    pub async fn upload_file(
        &self,
        data: &[u8],
        filename: &str,
        hash: &str,
        user_id: i64,
    ) -> Result<FileUploadResponse, StorageError> {
        // 去重检查
        if let Some(file) = self.check_dedup(hash).await? {
            let stored_ext = Path::new(&file.storage_path)
                .extension()
                .and_then(|e| e.to_str())
                .unwrap_or("bin")
                .to_string();
            return Ok(FileUploadResponse {
                file_id: file.id,
                file_url: format!("{}/{}", self.config.url_prefix, file.storage_path),
                file_name: filename.to_string(),
                file_size: file.size as u64,
                file_type: stored_ext,
                is_dedup: true,
            });
        }

        // 校验大小
        let file_size = data.len() as u64;
        if file_size > self.config.max_file_size {
            return Err(StorageError::FileTooLarge { size: file_size, max: self.config.max_file_size });
        }

        // 配额检查
        let quota = self.check_quota(user_id, file_size as i64).await?;

        // 生成路径
        let ext = Path::new(filename)
            .extension()
            .and_then(|e| e.to_str())
            .unwrap_or("bin")
            .to_lowercase();

        let date_path = Utc::now().format("%Y/%m").to_string();
        let file_uuid = Uuid::new_v4();
        let file_rel = format!("file/{}/{}.{}", date_path, file_uuid, ext);

        // 写入存储
        self.backend.put(&file_rel, data).await?;

        // 推断 mime_category
        let mime_category = match ext.as_str() {
            "mp3" | "wav" | "aac" | "ogg" | "m4a" => "audio",
            _ => "file",
        };
        let mime_type = mime_from_ext(&ext);

        // 写入数据库
        let original_name = truncate_filename(filename, 255);
        let file_obj = StorageRepo::insert_file_object(
            &self.db, hash, &file_rel, file_size as i64,
            &mime_type, mime_category,
            None, None, None, None, Some(&original_name), user_id,
        ).await?;

        // 扣减配额
        StorageRepo::update_quota_used(&self.db, user_id, file_size as i64).await?;
        self.notify_quota_changed(user_id, quota.used_bytes + file_size as i64, quota.quota_bytes);

        Ok(FileUploadResponse {
            file_id: file_obj.id,
            file_url: format!("{}/{}", self.config.url_prefix, file_rel),
            file_name: filename.to_string(),
            file_size,
            file_type: ext,
            is_dedup: false,
        })
    }

    /// 查询用户配额和分类用量
    pub async fn get_quota_info(&self, user_id: i64) -> Result<QuotaResponse, StorageError> {
        let quota = StorageRepo::get_quota(&self.db, user_id).await?
            .unwrap_or(UserStorageQuota {
                user_id,
                used_bytes: 0,
                quota_bytes: 104857600,
                updated_at: Utc::now(),
            });

        let usages = StorageRepo::get_usage_breakdown(&self.db, user_id).await?;
        let mut breakdown = std::collections::HashMap::new();
        for u in usages {
            breakdown.insert(u.mime_category, CategoryDetail {
                size: u.total_size,
                count: u.file_count,
            });
        }

        Ok(QuotaResponse {
            used_bytes: quota.used_bytes,
            quota_bytes: quota.quota_bytes,
            breakdown,
        })
    }

    /// 记录文件引用（消息发送后调用）
    pub async fn add_reference(
        &self,
        file_id: i64,
        message_id: uuid::Uuid,
        user_id: i64,
    ) -> Result<(), StorageError> {
        StorageRepo::insert_reference(&self.db, file_id, message_id, user_id).await?;
        Ok(())
    }

    /// 移除文件引用（消息撤回时调用）
    pub async fn remove_references_for_message(
        &self,
        message_id: uuid::Uuid,
    ) -> Result<(), StorageError> {
        let file_ids = StorageRepo::delete_references_by_message(&self.db, message_id).await?;
        for file_id in file_ids {
            StorageRepo::decrement_ref_count(&self.db, file_id).await?;
        }
        Ok(())
    }

    /// 删除文件（云空间管理）
    pub async fn delete_file(&self, file_id: i64, user_id: i64) -> Result<FileDeleteResponse, StorageError> {
        let file = StorageRepo::get_file_by_id(&self.db, file_id, user_id).await?
            .ok_or(StorageError::Io(std::io::Error::new(std::io::ErrorKind::NotFound, "文件不存在")))?;

        if file.ref_count > 1 {
            StorageRepo::decrement_ref_count(&self.db, file_id).await?;
            let quota = StorageRepo::get_quota(&self.db, user_id).await?
                .unwrap_or(UserStorageQuota { user_id, used_bytes: 0, quota_bytes: 104857600, updated_at: chrono::Utc::now() });
            return Ok(FileDeleteResponse {
                message: "引用计数已减少".to_string(),
                freed_bytes: 0,
                new_used_bytes: quota.used_bytes,
                new_quota_bytes: quota.quota_bytes,
            });
        }

        // ref_count = 1，物理删除
        let size = file.size;
        StorageRepo::delete_references_by_file(&self.db, file_id).await?;
        let _ = self.backend.delete(&file.storage_path).await;
        if let Some(ref thumb) = file.thumb_path {
            let _ = self.backend.delete(thumb).await;
        }
        StorageRepo::delete_file_object(&self.db, file_id).await?;
        StorageRepo::update_quota_used(&self.db, user_id, -size).await?;

        let quota = StorageRepo::get_quota(&self.db, user_id).await?
            .unwrap_or(UserStorageQuota { user_id, used_bytes: 0, quota_bytes: 104857600, updated_at: chrono::Utc::now() });
        self.notify_quota_changed(user_id, quota.used_bytes, quota.quota_bytes);

        Ok(FileDeleteResponse {
            message: "文件已删除".to_string(),
            freed_bytes: size,
            new_used_bytes: quota.used_bytes,
            new_quota_bytes: quota.quota_bytes,
        })
    }
}

/// 截断文件名，保留尾部（含扩展名），最大 255 字符
fn truncate_filename(name: &str, max_len: usize) -> String {
    if name.len() <= max_len {
        return name.to_string();
    }
    // 保留尾部 max_len 个字符（包含扩展名）
    let start = name.len() - max_len;
    format!("…{}", &name[start..])
}

/// 根据扩展名推断 MIME type
fn mime_from_ext(ext: &str) -> String {
    match ext {
        "pdf" => "application/pdf",
        "doc" | "docx" => "application/msword",
        "xls" | "xlsx" => "application/vnd.ms-excel",
        "ppt" | "pptx" => "application/vnd.ms-powerpoint",
        "zip" => "application/zip",
        "rar" => "application/x-rar-compressed",
        "txt" => "text/plain",
        "mp3" => "audio/mpeg",
        "wav" => "audio/wav",
        "aac" => "audio/aac",
        "ogg" => "audio/ogg",
        "m4a" => "audio/mp4",
        _ => "application/octet-stream",
    }.to_string()
}
