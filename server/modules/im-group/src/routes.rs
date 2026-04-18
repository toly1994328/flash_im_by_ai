use axum::{
    Router, Json,
    extract::State,
    http::{HeaderMap, StatusCode},
    routing::post,
};
use std::sync::Arc;

use flash_core::jwt::extract_user_id;
use im_message::MessageService;

use super::models::CreateGroupRequest;
use super::service::GroupService;

#[derive(Clone)]
pub struct GroupApiState {
    pub service: Arc<GroupService>,
    pub msg_service: Arc<MessageService>,
}

/// POST /groups — 创建群聊
async fn create_group(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Json(req): Json<CreateGroupRequest>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;

    let conv = state.service.create_group(user_id, &req.name, &req.member_ids).await?;

    // 发送系统消息 "XXX 创建了群聊"
    let creator_name: String = sqlx::query_as::<_, (String,)>(
        "SELECT COALESCE(nickname, '?') FROM user_profiles WHERE account_id = $1"
    )
    .bind(user_id)
    .fetch_optional(state.service.db())
    .await
    .ok()
    .flatten()
    .map(|(n,)| n)
    .unwrap_or_else(|| "?".to_string());

    let _ = state.msg_service.send_system(
        conv.id,
        format!("{} 创建了群聊", creator_name),
    ).await;

    Ok(Json(serde_json::to_value(conv).unwrap()))
}

pub fn group_routes(state: GroupApiState) -> Router {
    Router::new()
        .route("/groups", post(create_group))
        .with_state(state)
}
