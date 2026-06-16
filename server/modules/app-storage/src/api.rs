//! 文件上传 API + 配额查询 API

use std::sync::Arc;

use axum::{
    extract::{DefaultBodyLimit, Multipart, State},
    http::{HeaderMap, StatusCode},
    routing::{get, post},
    Json, Router,
};

use flash_core::jwt::extract_user_id;
use flash_core::AppError;

use crate::model::*;
use crate::service::{StorageError, StorageService, VideoUploadMetadata};
use crate::backend::local_fs::LocalFs;

type AppStorageService = StorageService<LocalFs>;

/// 将 StorageError 转为 HTTP 响应
fn map_storage_err(e: StorageError) -> (StatusCode, Json<serde_json::Value>) {
    match e {
        StorageError::QuotaExceeded { used_bytes, quota_bytes } => {
            let body = serde_json::json!({
                "code": "QUOTA_EXCEEDED",
                "message": "云空间不足",
                "used_bytes": used_bytes,
                "quota_bytes": quota_bytes,
            });
            (StatusCode::FORBIDDEN, Json(body))
        }
        StorageError::FileTooLarge { size, max } => {
            let body = serde_json::json!({
                "code": "FILE_TOO_LARGE",
                "message": format!("文件过大: {} bytes, 最大 {} bytes", size, max),
            });
            (StatusCode::BAD_REQUEST, Json(body))
        }
        StorageError::UnsupportedType(t) => {
            let body = serde_json::json!({
                "code": "UNSUPPORTED_TYPE",
                "message": format!("文件类型不支持: {}", t),
            });
            (StatusCode::BAD_REQUEST, Json(body))
        }
        _ => {
            println!("❌ [storage] {}", e);
            let body = serde_json::json!({
                "code": "INTERNAL_ERROR",
                "message": "服务器内部错误",
            });
            (StatusCode::INTERNAL_SERVER_ERROR, Json(body))
        }
    }
}

/// POST /api/upload/image
async fn upload_image(
    State(storage): State<Arc<AppStorageService>>,
    headers: HeaderMap,
    mut multipart: Multipart,
) -> Result<Json<ImageUploadResponse>, (StatusCode, Json<serde_json::Value>)> {
    let user_id = extract_user_id(&headers)
        .map_err(|_| {
            let body = serde_json::json!({"code": "UNAUTHORIZED", "message": "未登录"});
            (StatusCode::UNAUTHORIZED, Json(body))
        })?;

    let mut file_data: Option<(Vec<u8>, String)> = None;
    let mut hash: Option<String> = None;

    while let Ok(Some(field)) = multipart.next_field().await {
        let name = field.name().unwrap_or("").to_string();
        match name.as_str() {
            "file" => {
                let filename = field.file_name().unwrap_or("image.jpg").to_string();
                let data = field.bytes().await.map_err(|_| {
                    let body = serde_json::json!({"code": "BAD_REQUEST", "message": "读取文件失败"});
                    (StatusCode::BAD_REQUEST, Json(body))
                })?;
                file_data = Some((data.to_vec(), filename));
            }
            "hash" => {
                let text = field.text().await.unwrap_or_default();
                if !text.is_empty() {
                    hash = Some(text);
                }
            }
            _ => {}
        }
    }

    let (data, filename) = file_data.ok_or_else(|| {
        let body = serde_json::json!({"code": "BAD_REQUEST", "message": "缺少文件"});
        (StatusCode::BAD_REQUEST, Json(body))
    })?;

    let hash = hash.ok_or_else(|| {
        let body = serde_json::json!({"code": "BAD_REQUEST", "message": "缺少 hash"});
        (StatusCode::BAD_REQUEST, Json(body))
    })?;

    let result = storage.upload_image(&data, &filename, &hash, user_id).await
        .map_err(map_storage_err)?;

    Ok(Json(result))
}

/// POST /api/upload/video
async fn upload_video(
    State(storage): State<Arc<AppStorageService>>,
    headers: HeaderMap,
    mut multipart: Multipart,
) -> Result<Json<VideoUploadResponse>, (StatusCode, Json<serde_json::Value>)> {
    let user_id = extract_user_id(&headers)
        .map_err(|_| {
            let body = serde_json::json!({"code": "UNAUTHORIZED", "message": "未登录"});
            (StatusCode::UNAUTHORIZED, Json(body))
        })?;

    let mut video_data: Option<(Vec<u8>, String)> = None;
    let mut thumb_data: Option<Vec<u8>> = None;
    let mut hash: Option<String> = None;
    let mut duration_ms: u64 = 0;
    let mut width: u32 = 0;
    let mut height: u32 = 0;

    while let Ok(Some(field)) = multipart.next_field().await {
        let name = field.name().unwrap_or("").to_string();
        match name.as_str() {
            "video" => {
                let filename = field.file_name().unwrap_or("video.mp4").to_string();
                let data = field.bytes().await.map_err(|_| {
                    let body = serde_json::json!({"code": "BAD_REQUEST", "message": "读取视频失败"});
                    (StatusCode::BAD_REQUEST, Json(body))
                })?;
                video_data = Some((data.to_vec(), filename));
            }
            "thumbnail" => {
                let data = field.bytes().await.map_err(|_| {
                    let body = serde_json::json!({"code": "BAD_REQUEST", "message": "读取缩略图失败"});
                    (StatusCode::BAD_REQUEST, Json(body))
                })?;
                thumb_data = Some(data.to_vec());
            }
            "hash" => {
                let text = field.text().await.unwrap_or_default();
                if !text.is_empty() { hash = Some(text); }
            }
            "duration_ms" => {
                let text = field.text().await.unwrap_or_default();
                duration_ms = text.parse().unwrap_or(0);
            }
            "width" => {
                let text = field.text().await.unwrap_or_default();
                width = text.parse().unwrap_or(0);
            }
            "height" => {
                let text = field.text().await.unwrap_or_default();
                height = text.parse().unwrap_or(0);
            }
            _ => {}
        }
    }

    let (video_bytes, video_filename) = video_data.ok_or_else(|| {
        let body = serde_json::json!({"code": "BAD_REQUEST", "message": "缺少视频文件"});
        (StatusCode::BAD_REQUEST, Json(body))
    })?;
    let thumb_bytes = thumb_data.ok_or_else(|| {
        let body = serde_json::json!({"code": "BAD_REQUEST", "message": "缺少缩略图"});
        (StatusCode::BAD_REQUEST, Json(body))
    })?;
    let hash = hash.ok_or_else(|| {
        let body = serde_json::json!({"code": "BAD_REQUEST", "message": "缺少 hash"});
        (StatusCode::BAD_REQUEST, Json(body))
    })?;

    if duration_ms == 0 {
        let body = serde_json::json!({"code": "BAD_REQUEST", "message": "缺少 duration_ms"});
        return Err((StatusCode::BAD_REQUEST, Json(body)));
    }

    let metadata = VideoUploadMetadata { duration_ms, width, height };
    let result = storage.upload_video(
        &video_bytes, &video_filename, &thumb_bytes, &hash, user_id, metadata
    ).await.map_err(map_storage_err)?;

    Ok(Json(result))
}

/// POST /api/upload/file
async fn upload_file(
    State(storage): State<Arc<AppStorageService>>,
    headers: HeaderMap,
    mut multipart: Multipart,
) -> Result<Json<FileUploadResponse>, (StatusCode, Json<serde_json::Value>)> {
    let user_id = extract_user_id(&headers)
        .map_err(|_| {
            let body = serde_json::json!({"code": "UNAUTHORIZED", "message": "未登录"});
            (StatusCode::UNAUTHORIZED, Json(body))
        })?;

    let mut file_data: Option<(Vec<u8>, String)> = None;
    let mut hash: Option<String> = None;

    while let Ok(Some(field)) = multipart.next_field().await {
        let name = field.name().unwrap_or("").to_string();
        match name.as_str() {
            "file" => {
                let filename = field.file_name().unwrap_or("file.bin").to_string();
                let data = field.bytes().await.map_err(|_| {
                    let body = serde_json::json!({"code": "BAD_REQUEST", "message": "读取文件失败"});
                    (StatusCode::BAD_REQUEST, Json(body))
                })?;
                file_data = Some((data.to_vec(), filename));
            }
            "hash" => {
                let text = field.text().await.unwrap_or_default();
                if !text.is_empty() { hash = Some(text); }
            }
            _ => {}
        }
    }

    let (data, filename) = file_data.ok_or_else(|| {
        let body = serde_json::json!({"code": "BAD_REQUEST", "message": "缺少文件"});
        (StatusCode::BAD_REQUEST, Json(body))
    })?;
    let hash = hash.ok_or_else(|| {
        let body = serde_json::json!({"code": "BAD_REQUEST", "message": "缺少 hash"});
        (StatusCode::BAD_REQUEST, Json(body))
    })?;

    let result = storage.upload_file(&data, &filename, &hash, user_id).await
        .map_err(map_storage_err)?;

    Ok(Json(result))
}

/// GET /api/storage/quota
async fn get_quota(
    State(storage): State<Arc<AppStorageService>>,
    headers: HeaderMap,
) -> Result<Json<QuotaResponse>, AppError> {
    let user_id = extract_user_id(&headers)?;
    let result = storage.get_quota_info(user_id).await
        .map_err(|e| AppError::internal(e, "get_quota"))?;
    Ok(Json(result))
}

/// GET /api/storage/check?hash=xxx&size=xxx — 秒传检查 + 配额预检
///
/// 客户端上传前先用 hash + size 查询：
/// - 200：hash 已存在（秒传），直接返回文件信息
/// - 403：配额不足（QUOTA_EXCEEDED）
/// - 404：hash 不存在且配额充足，客户端可以上传
async fn check_hash(
    State(storage): State<Arc<AppStorageService>>,
    headers: HeaderMap,
    axum::extract::Query(params): axum::extract::Query<CheckHashQuery>,
) -> Result<Json<serde_json::Value>, (StatusCode, Json<serde_json::Value>)> {
    let user_id = extract_user_id(&headers)
        .map_err(|_| {
            let body = serde_json::json!({"code": "UNAUTHORIZED", "message": "未登录"});
            (StatusCode::UNAUTHORIZED, Json(body))
        })?;

    // 1. 先查 hash 是否已存在
    let existing = storage.check_file_exists(&params.hash).await
        .map_err(|e| {
            let body = serde_json::json!({"code": "INTERNAL_ERROR", "message": e.to_string()});
            (StatusCode::INTERNAL_SERVER_ERROR, Json(body))
        })?;

    if let Some(file) = existing {
        return Ok(Json(serde_json::json!({
            "exists": true,
            "file_id": file.id,
            "url": format!("/uploads/{}", file.storage_path),
            "thumb_url": file.thumb_path.map(|p| format!("/uploads/{}", p)),
            "size": file.size,
            "width": file.width,
            "height": file.height,
            "duration_ms": file.duration_ms,
            "mime_type": file.mime_type,
        })));
    }

    // 2. hash 不存在，检查配额是否充足
    if let Some(size) = params.size {
        let quota_check = storage.check_quota_only(user_id, size).await;
        if let Err(crate::service::StorageError::QuotaExceeded { used_bytes, quota_bytes }) = quota_check {
            let body = serde_json::json!({
                "code": "QUOTA_EXCEEDED",
                "message": "云空间不足",
                "used_bytes": used_bytes,
                "quota_bytes": quota_bytes,
            });
            return Err((StatusCode::FORBIDDEN, Json(body)));
        }
    }

    // 3. 不存在且配额充足 → 404，客户端可以上传
    let body = serde_json::json!({"exists": false});
    Err((StatusCode::NOT_FOUND, Json(body)))
}

#[derive(serde::Deserialize)]
struct CheckHashQuery {
    hash: String,
    size: Option<i64>,
}

/// 路由注册
pub fn storage_routes(storage: Arc<AppStorageService>) -> Router {
    let video_limit = storage.max_video_size() as usize;
    let file_limit = storage.max_file_size() as usize;
    Router::new()
        .route("/api/upload/image", post(upload_image))
        .route("/api/upload/video", post(upload_video).layer(DefaultBodyLimit::max(video_limit)))
        .route("/api/upload/file", post(upload_file).layer(DefaultBodyLimit::max(file_limit)))
        .route("/api/storage/quota", get(get_quota))
        .route("/api/storage/check", get(check_hash))
        .with_state(storage)
}
