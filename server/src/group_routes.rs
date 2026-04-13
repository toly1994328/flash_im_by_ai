//! 群聊路由（搜索、入群申请、审批、群主通知）
//!
//! 放在顶层而非 im-conversation crate 中，因为需要同时引用
//! im-conversation::ConversationService 和 im-ws::dispatcher::MessageDispatcher，
//! 而 im-conversation 不能依赖 im-ws（会形成循环依赖）。

use axum::{
    Router, Json,
    extract::{Path, Query, State},
    http::{HeaderMap, StatusCode},
    routing::{get, post},
};
use std::sync::Arc;
use uuid::Uuid;

use flash_core::jwt::extract_user_id;
use im_conversation::ConversationService;
use im_conversation::models::{SearchQuery, JoinGroupInput, HandleJoinInput, CreateConversationRequest};
use im_message::MessageService;
use im_ws::dispatcher::MessageDispatcher;

#[derive(Clone)]
pub struct GroupApiState {
    pub service: Arc<ConversationService>,
    pub dispatcher: Arc<MessageDispatcher>,
    pub msg_service: Arc<MessageService>,
}

/// POST /conversations — 统一创建入口（单聊/群聊）
async fn create_conversation(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Json(req): Json<CreateConversationRequest>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;

    match req.conv_type.as_str() {
        "private" => {
            let peer_id = req.peer_user_id.ok_or(StatusCode::BAD_REQUEST)?;
            let resp = state.service.create_private(user_id, peer_id).await?;
            Ok(Json(serde_json::to_value(resp).unwrap()))
        }
        "group" => {
            let name = req.name.as_deref().ok_or(StatusCode::BAD_REQUEST)?;
            let member_ids = req.member_ids.as_deref().ok_or(StatusCode::BAD_REQUEST)?;
            let resp = state.service.create_group(user_id, name, member_ids).await?;

            // 发送系统消息 "XXX 创建了群聊"，走完整消息流程（存储+广播+会话更新）
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
                resp.id,
                format!("{} 创建了群聊", creator_name),
            ).await;

            Ok(Json(serde_json::to_value(resp).unwrap()))
        }
        _ => Err(StatusCode::BAD_REQUEST),
    }
}

/// GET /conversations/search
async fn search_groups(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Query(query): Query<SearchQuery>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let results = state.service.search_groups(&query.keyword, user_id, query.limit).await?;
    Ok(Json(serde_json::to_value(results).unwrap()))
}

/// POST /conversations/{id}/join
async fn join_group(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Path(id): Path<String>,
    Json(req): Json<JoinGroupInput>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let conversation_id = Uuid::parse_str(&id).map_err(|_| StatusCode::BAD_REQUEST)?;

    let response = state.service
        .request_join(user_id, conversation_id, req.message.as_deref())
        .await?;

    // 需要审批时，WS 通知群主
    if !response.auto_approved {
        if let Some(ref owner_id_str) = response.owner_id {
            if let Ok(owner_id) = owner_id_str.parse::<i64>() {
                // 查询申请者信息
                let profile: Option<(String, Option<String>)> = sqlx::query_as(
                    "SELECT nickname, avatar FROM user_profiles WHERE account_id = $1"
                )
                .bind(user_id)
                .fetch_optional(state.service.db())
                .await
                .ok()
                .flatten();

                let (nickname, avatar) = profile.unwrap_or(("?".to_string(), None));

                // 查询最新的申请记录获取 request_id 和 created_at
                let request: Option<(uuid::Uuid, chrono::DateTime<chrono::Utc>)> = sqlx::query_as(
                    "SELECT id, created_at FROM group_join_requests
                     WHERE user_id = $1 AND conversation_id = $2 AND status = 0
                     ORDER BY created_at DESC LIMIT 1"
                )
                .bind(user_id)
                .bind(conversation_id)
                .fetch_optional(state.service.db())
                .await
                .ok()
                .flatten();

                if let Some((request_id, created_at)) = request {
                    state.dispatcher.notify_group_join_request(
                        owner_id,
                        &request_id.to_string(),
                        user_id,
                        &nickname,
                        avatar.as_deref(),
                        req.message.as_deref(),
                        &conversation_id.to_string(),
                        response.group_name.as_deref(),
                        created_at.timestamp_millis(),
                    ).await;
                }
            }
        }
    }

    Ok(Json(serde_json::to_value(response).unwrap()))
}

/// POST /conversations/{id}/join-requests/{rid}/handle
async fn handle_join_request(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Path((_id, rid)): Path<(String, String)>,
    Json(req): Json<HandleJoinInput>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let request_id = Uuid::parse_str(&rid).map_err(|_| StatusCode::BAD_REQUEST)?;
    state.service.handle_join_request(request_id, user_id, req.approved).await?;
    Ok(Json(serde_json::json!({ "data": null })))
}

/// GET /conversations/my-join-requests
async fn get_my_join_requests(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Query(params): Query<std::collections::HashMap<String, String>>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let limit = params.get("limit").and_then(|v| v.parse().ok()).unwrap_or(20);
    let offset = params.get("offset").and_then(|v| v.parse().ok()).unwrap_or(0);
    let list = state.service.get_my_join_requests(user_id, limit, offset).await?;
    Ok(Json(serde_json::to_value(list).unwrap()))
}

pub fn group_routes(state: GroupApiState) -> Router {
    Router::new()
        .route("/conversations", post(create_conversation))
        .route("/conversations/search", get(search_groups))
        .route("/conversations/my-join-requests", get(get_my_join_requests))
        .route("/conversations/{id}/join", post(join_group))
        .route("/conversations/{id}/join-requests/{rid}/handle", post(handle_join_request))
        .with_state(state)
}
