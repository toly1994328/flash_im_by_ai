use axum::{
    Router, Json,
    extract::{Path, State, Query},
    http::{HeaderMap, StatusCode},
    routing::get,
};
use std::sync::Arc;
use uuid::Uuid;
use sqlx;

use flash_core::jwt::extract_user_id;

use crate::models::{MessageQuery, NewMessage};
use crate::service::MessageService;

/// HTTP 发消息请求体
#[derive(Debug, serde::Deserialize)]
struct SendMessageBody {
    content: String,
    #[serde(default)]
    msg_type: i16,
    extra: Option<serde_json::Value>,
}

async fn get_messages(
    State(service): State<Arc<MessageService>>,
    headers: HeaderMap,
    Path(conversation_id): Path<String>,
    Query(query): Query<MessageQuery>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let _user_id = extract_user_id(&headers)?;
    let conv_id = Uuid::parse_str(&conversation_id)
        .map_err(|_| StatusCode::BAD_REQUEST)?;

    let messages = service.get_history(conv_id, query.before_seq, query.limit).await?;
    Ok(Json(serde_json::to_value(messages).unwrap()))
}

/// POST /conversations/{id}/messages — HTTP 发消息
///
/// 走和 WS 相同的 MessageService.send 链路（存储 + 广播 + 会话更新）
async fn send_message(
    State(service): State<Arc<MessageService>>,
    headers: HeaderMap,
    Path(conversation_id): Path<String>,
    Json(body): Json<SendMessageBody>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let conv_id = Uuid::parse_str(&conversation_id)
        .map_err(|_| StatusCode::BAD_REQUEST)?;

    let msg = NewMessage {
        conversation_id: conv_id,
        sender_id: user_id,
        content: body.content,
        msg_type: body.msg_type,
        extra: body.extra,
    };

    let message = service.send(msg).await?;
    Ok(Json(serde_json::to_value(message).unwrap()))
}

/// GET /conversations/{conv_id}/read-seq — 查询会话成员已读位置
async fn get_read_seq(
    State(service): State<Arc<MessageService>>,
    headers: HeaderMap,
    Path(conv_id_str): Path<String>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let conv_id = Uuid::parse_str(&conv_id_str).map_err(|_| StatusCode::BAD_REQUEST)?;

    let read_positions: Vec<(i64, i64)> = sqlx::query_as(
        "SELECT user_id, last_read_seq FROM conversation_members \
         WHERE conversation_id = $1 AND is_deleted = false AND user_id != $2"
    )
    .bind(conv_id)
    .bind(user_id)
    .fetch_all(service.db())
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let members_read_seq: serde_json::Map<String, serde_json::Value> = read_positions
        .into_iter()
        .map(|(uid, seq)| (uid.to_string(), serde_json::Value::from(seq)))
        .collect();

    Ok(Json(serde_json::json!({ "members_read_seq": members_read_seq })))
}

/// GET /conversations/{conv_id}/messages/{msg_id}/read-status — 已读详情
async fn get_read_status(
    State(service): State<Arc<MessageService>>,
    headers: HeaderMap,
    Path((conv_id_str, msg_id_str)): Path<(String, String)>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let _user_id = extract_user_id(&headers)?;
    let conv_id = Uuid::parse_str(&conv_id_str).map_err(|_| StatusCode::BAD_REQUEST)?;
    let msg_id = Uuid::parse_str(&msg_id_str).map_err(|_| StatusCode::BAD_REQUEST)?;

    // 1. 查消息的 seq 和 sender_id
    let msg_info: Option<(i64, i64)> = sqlx::query_as(
        "SELECT seq, sender_id FROM messages WHERE id = $1 AND conversation_id = $2"
    )
    .bind(msg_id)
    .bind(conv_id)
    .fetch_optional(service.db())
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let (msg_seq, sender_id) = msg_info.ok_or(StatusCode::NOT_FOUND)?;

    // 2. 查所有活跃成员的 last_read_seq（排除消息发送者）
    let members: Vec<(i64, i64, String, Option<String>)> = sqlx::query_as(
        "SELECT cm.user_id, cm.last_read_seq, \
                COALESCE(up.nickname, '未知用户'), up.avatar \
         FROM conversation_members cm \
         LEFT JOIN user_profiles up ON cm.user_id = up.account_id \
         WHERE cm.conversation_id = $1 AND cm.is_deleted = false AND cm.user_id != $2"
    )
    .bind(conv_id)
    .bind(sender_id)
    .fetch_all(service.db())
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 3. 分组
    let mut read_members = Vec::new();
    let mut unread_members = Vec::new();
    for (uid, last_read_seq, nickname, avatar) in members {
        let member = serde_json::json!({
            "user_id": uid,
            "nickname": nickname,
            "avatar": avatar,
        });
        if last_read_seq >= msg_seq {
            read_members.push(member);
        } else {
            unread_members.push(member);
        }
    }

    Ok(Json(serde_json::json!({
        "read_members": read_members,
        "unread_members": unread_members,
    })))
}

pub fn router(service: Arc<MessageService>) -> Router {
    Router::new()
        .route("/conversations/{id}/messages", get(get_messages).post(send_message))
        .route("/conversations/{conv_id}/read-seq", get(get_read_seq))
        .route("/conversations/{conv_id}/messages/{msg_id}/read-status", get(get_read_status))
        .with_state(service)
}
