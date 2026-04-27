use axum::{
    extract::{Path, Query, State},
    http::{HeaderMap, StatusCode},
    routing::{delete, get, post},
    Json, Router,
};
use std::sync::Arc;
use uuid::Uuid;
use sqlx;

use flash_core::jwt::extract_user_id;
use im_conversation::service::ConversationService;
use im_message::models::NewMessage;
use im_message::MessageService;
use im_ws::dispatcher::MessageDispatcher;

use crate::models::*;
use crate::service::FriendService;

/// 统一错误响应：返回 JSON body + 对应状态码
fn err_response(e: FriendError) -> (StatusCode, Json<serde_json::Value>) {
    let msg = e.to_string();
    let status = StatusCode::from(e);
    let body = Json(serde_json::json!({ "error": msg }));
    (status, body)
}

type ApiResult = Result<Json<serde_json::Value>, (StatusCode, Json<serde_json::Value>)>;

#[derive(Clone)]
pub struct FriendApiState {
    pub service: Arc<FriendService>,
    pub dispatcher: Option<Arc<MessageDispatcher>>,
    pub conv_service: Option<Arc<ConversationService>>,
    pub msg_service: Option<Arc<MessageService>>,
}

/// POST /api/friends/requests — 发送好友申请
async fn send_request(
    State(state): State<FriendApiState>,
    headers: HeaderMap,
    Json(req): Json<SendFriendRequestInput>,
) -> ApiResult {
    let user_id = extract_user_id(&headers).map_err(|s| (s, Json(serde_json::json!({"error":"未授权"}))))?;
    let request = state.service
        .send_request(user_id, req.to_user_id, req.message.as_deref())
        .await
        .map_err(err_response)?;

    // WS 通知被申请者
    if let Some(ref dispatcher) = state.dispatcher {
        let profile = state.service.repo().get_user_profile(user_id).await.ok().flatten();
        let (nickname, avatar) = profile.unwrap_or(("?".to_string(), None));
        dispatcher.notify_friend_request(
            req.to_user_id,
            &request.id.to_string(),
            user_id,
            &nickname,
            avatar.as_deref(),
            req.message.as_deref(),
            request.created_at.timestamp_millis(),
        ).await;
    }

    Ok(Json(serde_json::json!({ "data": request })))
}

/// GET /api/friends/requests/received
async fn get_received_requests(
    State(state): State<FriendApiState>,
    headers: HeaderMap,
    Query(query): Query<FriendListQuery>,
) -> ApiResult {
    let user_id = extract_user_id(&headers).map_err(|s| (s, Json(serde_json::json!({"error":"未授权"}))))?;
    let list = state.service
        .get_received_requests(user_id, query.limit, query.offset)
        .await
        .map_err(err_response)?;
    Ok(Json(serde_json::json!({ "data": list })))
}

/// GET /api/friends/requests/sent
async fn get_sent_requests(
    State(state): State<FriendApiState>,
    headers: HeaderMap,
    Query(query): Query<FriendListQuery>,
) -> ApiResult {
    let user_id = extract_user_id(&headers).map_err(|s| (s, Json(serde_json::json!({"error":"未授权"}))))?;
    let list = state.service
        .get_sent_requests(user_id, query.limit, query.offset)
        .await
        .map_err(err_response)?;
    Ok(Json(serde_json::json!({ "data": list })))
}

/// POST /api/friends/requests/:id/accept
async fn accept_request(
    State(state): State<FriendApiState>,
    headers: HeaderMap,
    Path(id): Path<String>,
) -> ApiResult {
    let user_id = extract_user_id(&headers).map_err(|s| (s, Json(serde_json::json!({"error":"未授权"}))))?;
    let request_id = Uuid::parse_str(&id).map_err(|_| (StatusCode::BAD_REQUEST, Json(serde_json::json!({"error":"无效的请求ID"}))))?;

    let req_info = state.service.repo()
        .find_request_by_id(request_id).await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({"error": e.to_string()}))))?
        .ok_or_else(|| (StatusCode::NOT_FOUND, Json(serde_json::json!({"error":"申请不存在"}))))?;

    let relation = state.service
        .accept_request(request_id, user_id)
        .await
        .map_err(err_response)?;

    let from_user_id = req_info.from_user_id;
    let greeting = req_info.message.clone()
        .unwrap_or_else(|| "我们已经是好友了，开始聊天吧".to_string());

    // 自动创建私聊会话
    if let Some(ref conv_service) = state.conv_service {
        match conv_service.create_private(from_user_id, user_id).await {
            Ok(conv) => {
                // 发送打招呼消息
                if let Some(ref msg_service) = state.msg_service {
                    let new_msg = NewMessage {
                        conversation_id: conv.id,
                        sender_id: from_user_id,
                        content: greeting,
                        msg_type: 0,
                        extra: None,
                    };
                    let _ = msg_service.send(new_msg).await;
                }
            }
            Err(e) => {
                println!("⚠️ [friend] create conversation failed: {:?}", e);
            }
        }
    }

    // WS 通知申请者：好友已接受
    if let Some(ref dispatcher) = state.dispatcher {
        let profile = state.service.repo().get_user_profile(user_id).await.ok().flatten();
        let (nickname, avatar) = profile.unwrap_or(("?".to_string(), None));
        dispatcher.notify_friend_accepted(
            from_user_id,
            user_id,
            &nickname,
            avatar.as_deref(),
            relation.created_at.timestamp_millis(),
        ).await;
    }

    Ok(Json(serde_json::json!({ "data": null })))
}

/// POST /api/friends/requests/:id/reject
async fn reject_request(
    State(state): State<FriendApiState>,
    headers: HeaderMap,
    Path(id): Path<String>,
) -> ApiResult {
    let user_id = extract_user_id(&headers).map_err(|s| (s, Json(serde_json::json!({"error":"未授权"}))))?;
    let request_id = Uuid::parse_str(&id).map_err(|_| (StatusCode::BAD_REQUEST, Json(serde_json::json!({"error":"无效的请求ID"}))))?;
    state.service
        .reject_request(request_id, user_id)
        .await
        .map_err(err_response)?;
    Ok(Json(serde_json::json!({ "data": null })))
}

/// GET /api/friends
async fn get_friends(
    State(state): State<FriendApiState>,
    headers: HeaderMap,
    Query(query): Query<FriendListQuery>,
) -> ApiResult {
    let user_id = extract_user_id(&headers).map_err(|s| (s, Json(serde_json::json!({"error":"未授权"}))))?;
    let list = state.service
        .get_friends(user_id, query.limit, query.offset)
        .await
        .map_err(err_response)?;
    Ok(Json(serde_json::json!({ "data": list })))
}

/// DELETE /api/friends/requests/:id — 删除申请记录
async fn delete_request(
    State(state): State<FriendApiState>,
    headers: HeaderMap,
    Path(id): Path<String>,
) -> ApiResult {
    let user_id = extract_user_id(&headers).map_err(|s| (s, Json(serde_json::json!({"error":"未授权"}))))?;
    let request_id = Uuid::parse_str(&id).map_err(|_| (StatusCode::BAD_REQUEST, Json(serde_json::json!({"error":"无效的请求ID"}))))?;
    state.service
        .delete_request(request_id, user_id)
        .await
        .map_err(err_response)?;
    Ok(Json(serde_json::json!({ "data": null })))
}

/// DELETE /api/friends/:id
async fn delete_friend(
    State(state): State<FriendApiState>,
    headers: HeaderMap,
    Path(id): Path<i64>,
) -> ApiResult {
    let user_id = extract_user_id(&headers).map_err(|s| (s, Json(serde_json::json!({"error":"未授权"}))))?;
    state.service
        .delete_friend(user_id, id)
        .await
        .map_err(err_response)?;

    // WS 通知双方
    if let Some(ref dispatcher) = state.dispatcher {
        dispatcher.notify_friend_removed(user_id, id).await;
        dispatcher.notify_friend_removed(id, user_id).await;
    }

    Ok(Json(serde_json::json!({ "data": null })))
}

/// GET /api/friends/search — 搜索好友（按昵称模糊匹配）
async fn search_friends(
    State(state): State<FriendApiState>,
    headers: HeaderMap,
    Query(query): Query<std::collections::HashMap<String, String>>,
) -> ApiResult {
    let user_id = extract_user_id(&headers).map_err(|s| (s, Json(serde_json::json!({"error":"未授权"}))))?;
    let keyword = query.get("keyword").cloned().unwrap_or_default();
    let limit: i32 = query.get("limit").and_then(|v| v.parse().ok()).unwrap_or(20).min(50).max(1);

    let escaped = keyword.replace('%', "\\%").replace('_', "\\_");
    let pattern = format!("%{}%", escaped);

    let rows: Vec<(i64, String, Option<String>)> = sqlx::query_as(
        "SELECT fr.friend_id, COALESCE(up.nickname, '?') AS nickname, up.avatar \
         FROM friend_relations fr \
         LEFT JOIN user_profiles up ON up.account_id = fr.friend_id \
         WHERE fr.user_id = $1 AND up.nickname ILIKE $2 \
         ORDER BY up.nickname \
         LIMIT $3"
    )
    .bind(user_id)
    .bind(&pattern)
    .bind(limit)
    .fetch_all(state.service.repo().pool())
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({"error": e.to_string()}))))?;

    let data: Vec<serde_json::Value> = rows.into_iter().map(|(id, nickname, avatar)| {
        serde_json::json!({ "friend_id": id.to_string(), "nickname": nickname, "avatar": avatar })
    }).collect();

    Ok(Json(serde_json::json!({ "data": data })))
}

pub fn friend_routes(state: FriendApiState) -> Router {
    Router::new()
        .route("/api/friends/requests", post(send_request))
        .route("/api/friends/requests/received", get(get_received_requests))
        .route("/api/friends/requests/sent", get(get_sent_requests))
        .route("/api/friends/requests/{id}/accept", post(accept_request))
        .route("/api/friends/requests/{id}/reject", post(reject_request))
        .route("/api/friends/requests/{id}", delete(delete_request))
        .route("/api/friends", get(get_friends))
        .route("/api/friends/search", get(search_friends))
        .route("/api/friends/{id}", delete(delete_friend))
        .with_state(state)
}
