use axum::{
    Router, Json,
    extract::{Path, State},
    http::{HeaderMap, StatusCode},
    routing::{get, post, delete},
};
use std::sync::Arc;
use uuid::Uuid;

use flash_core::jwt::extract_user_id;
use flash_core::state::AppState;
use sqlx;

use super::models::{CreatePrivateRequest, MessageResponse};
use super::service::ConversationService;

async fn create_conversation(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<CreatePrivateRequest>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let service = ConversationService::new(state.db.clone());
    let resp = service.create_private(user_id, req.peer_user_id).await?;
    Ok(Json(serde_json::to_value(resp).unwrap()))
}

async fn list_conversations(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    axum::extract::Query(params): axum::extract::Query<std::collections::HashMap<String, String>>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let limit = params.get("limit").and_then(|v| v.parse().ok()).unwrap_or(20);
    let offset = params.get("offset").and_then(|v| v.parse().ok()).unwrap_or(0);
    let service = ConversationService::new(state.db.clone());
    let list = service.get_list(user_id, limit, offset).await?;
    Ok(Json(serde_json::to_value(list).unwrap()))
}

async fn delete_conversation(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Path(id): Path<String>,
) -> Result<Json<MessageResponse>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let conversation_id = Uuid::parse_str(&id).map_err(|_| StatusCode::BAD_REQUEST)?;
    let service = ConversationService::new(state.db.clone());
    service.delete_for_user(conversation_id, user_id).await?;
    Ok(Json(MessageResponse { message: "会话已删除".to_string() }))
}

async fn mark_read(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Path(id): Path<String>,
) -> Result<Json<MessageResponse>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let conversation_id = Uuid::parse_str(&id).map_err(|_| StatusCode::BAD_REQUEST)?;
    sqlx::query(
        "UPDATE conversation_members SET unread_count = 0 \
         WHERE conversation_id = $1 AND user_id = $2",
    )
    .bind(conversation_id)
    .bind(user_id)
    .execute(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    Ok(Json(MessageResponse { message: "ok".to_string() }))
}

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/conversations", post(create_conversation).get(list_conversations))
        .route("/conversations/{id}", delete(delete_conversation))
        .route("/conversations/{id}/read", post(mark_read))
}
