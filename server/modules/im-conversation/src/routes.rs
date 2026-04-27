use axum::{
    Router, Json,
    extract::{Path, State},
    http::{HeaderMap, StatusCode},
    routing::{post, delete, get},
};
use std::sync::Arc;
use uuid::Uuid;

use flash_core::jwt::extract_user_id;
use flash_core::state::AppState;

use super::models::{MessageResponse, CreatePrivateRequest};
use super::service::ConversationService;

/// POST /conversations — 创建单聊会话
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
    let conv_type = params.get("type").and_then(|v| v.parse::<i16>().ok());
    let service = ConversationService::new(state.db.clone());
    let list = service.get_list(user_id, limit, offset, conv_type).await?;
    Ok(Json(serde_json::to_value(list).unwrap()))
}

async fn get_conversation(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Path(id): Path<String>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let conversation_id = Uuid::parse_str(&id).map_err(|_| StatusCode::BAD_REQUEST)?;
    let service = ConversationService::new(state.db.clone());
    let resp = service.get_by_id(conversation_id, user_id).await?;
    Ok(Json(serde_json::to_value(resp).unwrap()))
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

/// GET /api/conversations/search-joined-groups — 搜索已加入的群聊
async fn search_joined_groups(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    axum::extract::Query(params): axum::extract::Query<std::collections::HashMap<String, String>>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let keyword = params.get("keyword").cloned().unwrap_or_default();
    let limit: i32 = params.get("limit").and_then(|v| v.parse().ok()).unwrap_or(20).min(50).max(1);

    let escaped = keyword.replace('%', "\\%").replace('_', "\\_");
    let pattern = format!("%{}%", escaped);

    let rows: Vec<(Uuid, Option<String>, Option<String>, i64)> = sqlx::query_as(
        "SELECT c.id, c.name, c.avatar, \
            (SELECT COUNT(*) FROM conversation_members WHERE conversation_id = c.id AND is_deleted = false) AS member_count \
         FROM conversations c \
         INNER JOIN conversation_members cm ON cm.conversation_id = c.id AND cm.user_id = $1 AND cm.is_deleted = false \
         WHERE c.type = 1 AND COALESCE(c.status, 0::SMALLINT) = 0 AND c.name ILIKE $2 \
         ORDER BY c.name \
         LIMIT $3"
    )
    .bind(user_id)
    .bind(&pattern)
    .bind(limit)
    .fetch_all(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let data: Vec<serde_json::Value> = rows.into_iter().map(|(id, name, avatar, count)| {
        serde_json::json!({
            "conversation_id": id.to_string(),
            "name": name,
            "avatar": avatar,
            "member_count": count,
        })
    }).collect();

    Ok(Json(serde_json::json!({ "data": data })))
}

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/conversations", post(create_conversation).get(list_conversations))
        .route("/conversations/{id}", delete(delete_conversation).get(get_conversation))
        .route("/conversations/{id}/read", post(mark_read))
        .route("/api/conversations/search-joined-groups", get(search_joined_groups))
}
