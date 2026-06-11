use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    Json,
};
use serde::Deserialize;
use std::sync::Arc;

use flash_core::jwt::extract_user_id;
use flash_core::state::AppState;
use flash_core::AppError;
use super::model::MessageResponse;

#[derive(Deserialize)]
pub struct CreateReportRequest {
    pub target_type: i16,
    pub target_id: String,
    pub reason: i16,
    pub description: Option<String>,
}

/// POST /api/reports
pub async fn create_report(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<CreateReportRequest>,
) -> Result<(StatusCode, Json<MessageResponse>), AppError> {
    let reporter_id = extract_user_id(&headers)?;

    // 校验
    if !(0..=1).contains(&req.target_type) {
        return Err(AppError::bad_request("target_type 无效"));
    }
    if !(0..=4).contains(&req.reason) {
        return Err(AppError::bad_request("reason 无效"));
    }
    if req.target_id.is_empty() {
        return Err(AppError::bad_request("target_id 不能为空"));
    }

    sqlx::query(
        "INSERT INTO reports (reporter_id, target_type, target_id, reason, description) \
         VALUES ($1, $2, $3, $4, $5)"
    )
    .bind(reporter_id)
    .bind(req.target_type)
    .bind(&req.target_id)
    .bind(req.reason)
    .bind(&req.description)
    .execute(&state.db)
    .await?;

    println!("🚨 举报: reporter={}, type={}, target={}, reason={}", reporter_id, req.target_type, req.target_id, req.reason);

    Ok((StatusCode::CREATED, Json(MessageResponse { message: "举报已提交".into() })))
}
