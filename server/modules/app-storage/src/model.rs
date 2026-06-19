use chrono::{DateTime, Utc};
use serde::Serialize;
use sqlx::FromRow;
use std::collections::HashMap;

/// 文件对象（对应 file_objects 表）
#[derive(Debug, Clone, FromRow)]
pub struct FileObject {
    pub id: i64,
    pub hash: String,
    pub storage_path: String,
    pub size: i64,
    pub mime_type: String,
    pub mime_category: String,
    pub width: Option<i32>,
    pub height: Option<i32>,
    pub duration_ms: Option<i64>,
    pub thumb_path: Option<String>,
    pub original_name: Option<String>,
    pub ref_count: i32,
    pub uploader_id: i64,
    pub created_at: DateTime<Utc>,
}

/// 用户云存储配额（对应 user_storage_quota 表）
#[derive(Debug, Clone, FromRow)]
pub struct UserStorageQuota {
    pub user_id: i64,
    pub used_bytes: i64,
    pub quota_bytes: i64,
    pub updated_at: DateTime<Utc>,
}

/// 分类用量聚合结果
#[derive(Debug, Clone, FromRow)]
pub struct CategoryUsage {
    pub mime_category: String,
    pub total_size: i64,
    pub file_count: i64,
}

// ─── API 响应类型 ───

/// 图片上传响应
#[derive(Debug, Serialize)]
pub struct ImageUploadResponse {
    pub file_id: i64,
    pub original_url: String,
    pub thumbnail_url: String,
    pub width: u32,
    pub height: u32,
    pub size: u64,
    pub format: String,
    pub is_dedup: bool,
}

/// 视频上传响应
#[derive(Debug, Serialize)]
pub struct VideoUploadResponse {
    pub file_id: i64,
    pub video_url: String,
    pub thumbnail_url: String,
    pub duration_ms: u64,
    pub width: u32,
    pub height: u32,
    pub file_size: u64,
    pub is_dedup: bool,
}

/// 文件上传响应
#[derive(Debug, Serialize)]
pub struct FileUploadResponse {
    pub file_id: i64,
    pub file_url: String,
    pub file_name: String,
    pub file_size: u64,
    pub file_type: String,
    pub is_dedup: bool,
}

/// 配额查询响应
#[derive(Debug, Serialize)]
pub struct QuotaResponse {
    pub used_bytes: i64,
    pub quota_bytes: i64,
    pub breakdown: HashMap<String, CategoryDetail>,
}

/// 分类详情
#[derive(Debug, Serialize)]
pub struct CategoryDetail {
    pub size: i64,
    pub count: i64,
}

/// 配额不足错误响应
#[derive(Debug, Serialize)]
pub struct QuotaExceededResponse {
    pub code: &'static str,
    pub message: &'static str,
    pub used_bytes: i64,
    pub quota_bytes: i64,
}

// ─── 云空间 Tab 接口响应 ───

/// 文件列表响应
#[derive(Debug, Serialize)]
pub struct FileListResponse {
    pub data: Vec<FileListItem>,
    pub total: i64,
    pub page: i64,
    pub limit: i64,
}

/// 文件列表项
#[derive(Debug, Serialize)]
pub struct FileListItem {
    pub id: i64,
    pub url: String,
    pub thumb_url: Option<String>,
    pub size: i64,
    pub mime_type: String,
    pub mime_category: String,
    pub width: Option<i32>,
    pub height: Option<i32>,
    pub duration_ms: Option<i64>,
    pub original_name: Option<String>,
    pub ref_count: i32,
    pub created_at: DateTime<Utc>,
}

/// 文件详情响应
#[derive(Debug, Serialize)]
pub struct FileDetailResponse {
    pub file: FileListItem,
    pub conversations: Vec<FileConversationRef>,
}

/// 文件引用的会话
#[derive(Debug, Serialize)]
pub struct FileConversationRef {
    pub conversation_id: String,
    pub conversation_name: String,
    pub conversation_type: i16,
    pub avatar: Option<String>,
    pub message_count: i64,
}

/// 文件删除响应
#[derive(Debug, Serialize)]
pub struct FileDeleteResponse {
    pub message: String,
    pub freed_bytes: i64,
    pub new_used_bytes: i64,
    pub new_quota_bytes: i64,
}
