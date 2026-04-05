//! 文件存储服务

use std::path::{Path, PathBuf};

use chrono::Utc;
use thiserror::Error;
use tokio::fs;
use uuid::Uuid;

use crate::image::ImageProcessor;

/// 存储错误类型
#[derive(Debug, Error)]
pub enum StorageError {
    #[error("文件不存在: {0}")]
    NotFound(String),

    #[error("文件类型不支持: {0}")]
    UnsupportedType(String),

    #[error("文件过大: {size} bytes, 最大允许 {max} bytes")]
    FileTooLarge { size: u64, max: u64 },

    #[error("IO 错误: {0}")]
    Io(#[from] std::io::Error),

    #[error("图片处理错误: {0}")]
    Image(#[from] crate::image::ImageError),
}

/// 上传结果（图片）
#[derive(Debug, Clone)]
pub struct UploadResult {
    pub original_url: String,
    pub thumbnail_url: Option<String>,
    pub width: Option<u32>,
    pub height: Option<u32>,
    pub size: u64,
    pub format: String,
}

/// 前端提供的视频元数据
#[derive(Debug, Clone)]
pub struct VideoUploadMetadata {
    pub duration_ms: u64,
    pub width: u32,
    pub height: u32,
}

/// 视频上传结果
#[derive(Debug, Clone)]
pub struct VideoUploadResult {
    pub video_url: String,
    pub thumbnail_url: String,
    pub duration_ms: u64,
    pub width: u32,
    pub height: u32,
    pub file_size: u64,
}

/// 文件上传结果
#[derive(Debug, Clone)]
pub struct FileUploadResult {
    pub file_url: String,
    pub file_name: String,
    pub file_size: u64,
    pub file_type: String,
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
            max_image_size: 10 * 1024 * 1024,  // 10MB
            max_video_size: 50 * 1024 * 1024,   // 50MB
            max_file_size: 50 * 1024 * 1024,     // 50MB
            thumbnail_max_size: 200,
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
        if let Ok(v) = std::env::var("UPLOAD_MAX_IMAGE_SIZE") {
            if let Ok(n) = v.parse() { config.max_image_size = n; }
        }
        if let Ok(v) = std::env::var("UPLOAD_MAX_VIDEO_SIZE") {
            if let Ok(n) = v.parse() { config.max_video_size = n; }
        }
        if let Ok(v) = std::env::var("UPLOAD_MAX_FILE_SIZE") {
            if let Ok(n) = v.parse() { config.max_file_size = n; }
        }
        config
    }
}

/// 文件存储服务
#[derive(Clone)]
pub struct StorageService {
    config: StorageConfig,
    image_processor: ImageProcessor,
}

impl StorageService {
    pub fn new(config: StorageConfig) -> Self {
        let image_processor = ImageProcessor::new(
            config.thumbnail_max_size,
            config.thumbnail_quality,
        );
        Self { config, image_processor }
    }

    pub fn max_video_size(&self) -> u64 {
        self.config.max_video_size
    }

    pub fn max_file_size(&self) -> u64 {
        self.config.max_file_size
    }

    /// 上传图片
    pub async fn upload_image(
        &self,
        data: &[u8],
        filename: &str,
    ) -> Result<UploadResult, StorageError> {
        let size = data.len() as u64;
        if size > self.config.max_image_size {
            return Err(StorageError::FileTooLarge {
                size,
                max: self.config.max_image_size,
            });
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

        let date_path = Utc::now().format("%Y/%m").to_string();
        let file_id = Uuid::new_v4();
        let original_filename = format!("{file_id}.{ext}");
        let thumb_filename = format!("{file_id}.webp");

        let original_dir = self.config.base_path.join("original").join(&date_path);
        let thumb_dir = self.config.base_path.join("thumb").join(&date_path);
        fs::create_dir_all(&original_dir).await?;
        fs::create_dir_all(&thumb_dir).await?;

        // 保存原图
        let original_path = original_dir.join(&original_filename);
        fs::write(&original_path, data).await?;

        // 生成缩略图
        let (width, height, thumb_data) = self.image_processor.process(data)?;

        let thumb_path = thumb_dir.join(&thumb_filename);
        fs::write(&thumb_path, &thumb_data).await?;

        let original_url = format!(
            "{}/original/{}/{}",
            self.config.url_prefix, date_path, original_filename
        );
        let thumbnail_url = format!(
            "{}/thumb/{}/{}",
            self.config.url_prefix, date_path, thumb_filename
        );

        Ok(UploadResult {
            original_url,
            thumbnail_url: Some(thumbnail_url),
            width: Some(width),
            height: Some(height),
            size,
            format: format.to_string(),
        })
    }

    /// 上传视频
    pub async fn upload_video(
        &self,
        video_data: &[u8],
        video_filename: &str,
        thumb_data: &[u8],
        metadata: VideoUploadMetadata,
    ) -> Result<VideoUploadResult, StorageError> {
        let file_size = video_data.len() as u64;
        if file_size > self.config.max_video_size {
            return Err(StorageError::FileTooLarge {
                size: file_size,
                max: self.config.max_video_size,
            });
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

        let date_path = Utc::now().format("%Y/%m").to_string();
        let file_id = Uuid::new_v4();
        let video_stored_name = format!("{file_id}.{ext}");
        let thumb_stored_name = format!("{file_id}.jpg");

        let video_dir = self.config.base_path.join("video").join(&date_path);
        let thumb_dir = self.config.base_path.join("thumb").join(&date_path);
        fs::create_dir_all(&video_dir).await?;
        fs::create_dir_all(&thumb_dir).await?;

        fs::write(video_dir.join(&video_stored_name), video_data).await?;
        fs::write(thumb_dir.join(&thumb_stored_name), thumb_data).await?;

        let video_url = format!(
            "{}/video/{}/{}",
            self.config.url_prefix, date_path, video_stored_name
        );
        let thumbnail_url = format!(
            "{}/thumb/{}/{}",
            self.config.url_prefix, date_path, thumb_stored_name
        );

        Ok(VideoUploadResult {
            video_url,
            thumbnail_url,
            duration_ms: metadata.duration_ms,
            width: metadata.width,
            height: metadata.height,
            file_size,
        })
    }

    /// 上传文件
    pub async fn upload_file(
        &self,
        data: &[u8],
        filename: &str,
    ) -> Result<FileUploadResult, StorageError> {
        let file_size = data.len() as u64;
        if file_size > self.config.max_file_size {
            return Err(StorageError::FileTooLarge {
                size: file_size,
                max: self.config.max_file_size,
            });
        }

        let ext = Path::new(filename)
            .extension()
            .and_then(|e| e.to_str())
            .unwrap_or("bin")
            .to_lowercase();

        let date_path = Utc::now().format("%Y/%m").to_string();
        let file_id = Uuid::new_v4();
        let stored_name = format!("{file_id}.{ext}");

        let file_dir = self.config.base_path.join("file").join(&date_path);
        fs::create_dir_all(&file_dir).await?;

        fs::write(file_dir.join(&stored_name), data).await?;

        let file_url = format!(
            "{}/file/{}/{}",
            self.config.url_prefix, date_path, stored_name
        );

        Ok(FileUploadResult {
            file_url,
            file_name: filename.to_string(),
            file_size,
            file_type: ext,
        })
    }
}
