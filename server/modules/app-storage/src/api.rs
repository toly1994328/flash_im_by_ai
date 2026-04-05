//! 文件上传 API

use std::sync::Arc;

use axum::{
    extract::{DefaultBodyLimit, Multipart, State},
    http::StatusCode,
    routing::post,
    Json, Router,
};
use serde::Serialize;

use crate::service::{StorageService, UploadResult, VideoUploadMetadata};

#[derive(Debug, Serialize)]
pub struct ImageUploadResponse {
    pub original_url: String,
    pub thumbnail_url: String,
    pub width: u32,
    pub height: u32,
    pub size: u64,
    pub format: String,
}

impl From<UploadResult> for ImageUploadResponse {
    fn from(r: UploadResult) -> Self {
        Self {
            original_url: r.original_url,
            thumbnail_url: r.thumbnail_url.unwrap_or_default(),
            width: r.width.unwrap_or(0),
            height: r.height.unwrap_or(0),
            size: r.size,
            format: r.format,
        }
    }
}

#[derive(Debug, Serialize)]
pub struct VideoUploadResponse {
    pub video_url: String,
    pub thumbnail_url: String,
    pub duration_ms: u64,
    pub width: u32,
    pub height: u32,
    pub file_size: u64,
}

#[derive(Debug, Serialize)]
pub struct FileUploadResponse {
    pub file_url: String,
    pub file_name: String,
    pub file_size: u64,
    pub file_type: String,
}

fn storage_err(e: crate::service::StorageError) -> StatusCode {
    println!("❌ [storage] {}", e);
    match e {
        crate::service::StorageError::FileTooLarge { .. } => StatusCode::BAD_REQUEST,
        crate::service::StorageError::UnsupportedType(_) => StatusCode::BAD_REQUEST,
        _ => StatusCode::INTERNAL_SERVER_ERROR,
    }
}

async fn upload_image(
    State(storage): State<Arc<StorageService>>,
    mut multipart: Multipart,
) -> Result<Json<ImageUploadResponse>, StatusCode> {
    let field = multipart.next_field().await
        .map_err(|_| StatusCode::BAD_REQUEST)?
        .ok_or(StatusCode::BAD_REQUEST)?;

    let filename = field.file_name()
        .unwrap_or("image.jpg")
        .to_string();
    let data = field.bytes().await
        .map_err(|_| StatusCode::BAD_REQUEST)?;

    let result = storage.upload_image(&data, &filename).await.map_err(storage_err)?;
    Ok(Json(result.into()))
}

async fn upload_video(
    State(storage): State<Arc<StorageService>>,
    mut multipart: Multipart,
) -> Result<Json<VideoUploadResponse>, StatusCode> {
    let mut video_data: Option<(Vec<u8>, String)> = None;
    let mut thumb_data: Option<Vec<u8>> = None;
    let mut duration_ms: u64 = 0;
    let mut width: u32 = 0;
    let mut height: u32 = 0;

    while let Ok(Some(field)) = multipart.next_field().await {
        let name = field.name().unwrap_or("").to_string();
        match name.as_str() {
            "video" => {
                let filename = field.file_name()
                    .unwrap_or("video.mp4")
                    .to_string();
                let data = field.bytes().await.map_err(|_| StatusCode::BAD_REQUEST)?;
                video_data = Some((data.to_vec(), filename));
            }
            "thumbnail" => {
                let data = field.bytes().await.map_err(|_| StatusCode::BAD_REQUEST)?;
                thumb_data = Some(data.to_vec());
            }
            "duration_ms" => {
                let text = field.text().await.map_err(|_| StatusCode::BAD_REQUEST)?;
                duration_ms = text.parse().unwrap_or(0);
            }
            "width" => {
                let text = field.text().await.map_err(|_| StatusCode::BAD_REQUEST)?;
                width = text.parse().unwrap_or(0);
            }
            "height" => {
                let text = field.text().await.map_err(|_| StatusCode::BAD_REQUEST)?;
                height = text.parse().unwrap_or(0);
            }
            _ => {}
        }
    }

    let (video_bytes, video_filename) = video_data.ok_or(StatusCode::BAD_REQUEST)?;
    let thumb_bytes = thumb_data.ok_or(StatusCode::BAD_REQUEST)?;
    if duration_ms == 0 { return Err(StatusCode::BAD_REQUEST); }

    let metadata = VideoUploadMetadata { duration_ms, width, height };
    let result = storage
        .upload_video(&video_bytes, &video_filename, &thumb_bytes, metadata)
        .await
        .map_err(storage_err)?;

    Ok(Json(VideoUploadResponse {
        video_url: result.video_url,
        thumbnail_url: result.thumbnail_url,
        duration_ms: result.duration_ms,
        width: result.width,
        height: result.height,
        file_size: result.file_size,
    }))
}

async fn upload_file(
    State(storage): State<Arc<StorageService>>,
    mut multipart: Multipart,
) -> Result<Json<FileUploadResponse>, StatusCode> {
    let field = multipart.next_field().await
        .map_err(|_| StatusCode::BAD_REQUEST)?
        .ok_or(StatusCode::BAD_REQUEST)?;

    let filename = field.file_name()
        .unwrap_or("file.bin")
        .to_string();
    let data = field.bytes().await
        .map_err(|_| StatusCode::BAD_REQUEST)?;

    let result = storage.upload_file(&data, &filename).await.map_err(storage_err)?;

    Ok(Json(FileUploadResponse {
        file_url: result.file_url,
        file_name: result.file_name,
        file_size: result.file_size,
        file_type: result.file_type,
    }))
}

pub fn storage_routes(storage: Arc<StorageService>) -> Router {
    let video_limit = storage.max_video_size() as usize;
    let file_limit = storage.max_file_size() as usize;
    Router::new()
        .route("/api/upload/image", post(upload_image))
        .route("/api/upload/video", post(upload_video).layer(DefaultBodyLimit::max(video_limit)))
        .route("/api/upload/file", post(upload_file).layer(DefaultBodyLimit::max(file_limit)))
        .with_state(storage)
}
