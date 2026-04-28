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

/// GET /api/messages/search — 跨会话消息搜索（按会话分组）
async fn search_messages(
    State(service): State<Arc<MessageService>>,
    headers: HeaderMap,
    Query(query): Query<std::collections::HashMap<String, String>>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let keyword = query.get("keyword").cloned().unwrap_or_default();
    let limit: i32 = query.get("limit").and_then(|v| v.parse().ok()).unwrap_or(10).min(20).max(1);

    let escaped = keyword.replace('%', "\\%").replace('_', "\\_");
    let pattern = format!("%{}%", escaped);

    // 第一步：找匹配的会话及匹配数
    let groups: Vec<(Uuid, i64)> = sqlx::query_as(
        "SELECT m.conversation_id, COUNT(*) AS match_count \
         FROM messages m \
         INNER JOIN conversation_members cm ON cm.conversation_id = m.conversation_id AND cm.user_id = $1 AND cm.is_deleted = false \
         WHERE m.type = 0 AND m.sender_id != 0 AND m.content ILIKE $2 \
         GROUP BY m.conversation_id \
         ORDER BY MAX(m.created_at) DESC \
         LIMIT $3"
    )
    .bind(user_id).bind(&pattern).bind(limit)
    .fetch_all(service.db())
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let mut result = Vec::new();
    for (conv_id, match_count) in groups {
        // 会话信息
        let conv_info: Option<(Option<String>, Option<String>, i16)> = sqlx::query_as(
            "SELECT name, avatar, type FROM conversations WHERE id = $1"
        ).bind(conv_id).fetch_optional(service.db()).await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        let (conv_name_raw, conv_avatar_raw, conv_type) = conv_info.unwrap_or((None, None, 0));

        // 单聊：取对方昵称和头像
        let (conversation_name, conversation_avatar) = if conv_type == 0 {
            let peer: Option<(String, Option<String>)> = sqlx::query_as(
                "SELECT COALESCE(up.nickname, '?'), up.avatar \
                 FROM conversation_members cm \
                 LEFT JOIN user_profiles up ON up.account_id = cm.user_id \
                 WHERE cm.conversation_id = $1 AND cm.user_id != $2 AND cm.is_deleted = false \
                 LIMIT 1"
            ).bind(conv_id).bind(user_id).fetch_optional(service.db()).await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
            peer.unwrap_or(("?".to_string(), None))
        } else {
            (conv_name_raw.unwrap_or("?".to_string()), conv_avatar_raw)
        };

        // 最近 3 条匹配消息
        let messages: Vec<(Uuid, String, Option<String>, String, chrono::DateTime<chrono::Utc>)> = sqlx::query_as(
            "SELECT m.id, COALESCE(up.nickname, '?'), up.avatar, m.content, m.created_at \
             FROM messages m \
             LEFT JOIN user_profiles up ON up.account_id = m.sender_id \
             WHERE m.conversation_id = $1 AND m.type = 0 AND m.sender_id != 0 AND m.content ILIKE $2 \
             ORDER BY m.created_at DESC \
             LIMIT 3"
        ).bind(conv_id).bind(&pattern).fetch_all(service.db()).await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        let msg_list: Vec<serde_json::Value> = messages.into_iter().map(|(id, name, avatar, content, created_at)| {
            serde_json::json!({
                "message_id": id.to_string(),
                "sender_name": name,
                "sender_avatar": avatar,
                "content": content,
                "created_at": created_at.to_rfc3339(),
            })
        }).collect();

        result.push(serde_json::json!({
            "conversation_id": conv_id.to_string(),
            "conversation_name": conversation_name,
            "conversation_avatar": conversation_avatar,
            "conv_type": conv_type,
            "match_count": match_count,
            "messages": msg_list,
        }));
    }

    Ok(Json(serde_json::json!({ "data": result })))
}

/// GET /conversations/{conv_id}/messages/search — 会话内消息搜索
async fn search_conversation_messages(
    State(service): State<Arc<MessageService>>,
    headers: HeaderMap,
    Path(conv_id_str): Path<String>,
    Query(params): Query<std::collections::HashMap<String, String>>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let _user_id = extract_user_id(&headers)?;
    let conv_id = Uuid::parse_str(&conv_id_str).map_err(|_| StatusCode::BAD_REQUEST)?;
    let keyword = params.get("keyword").cloned().unwrap_or_default();
    let limit: i32 = params.get("limit").and_then(|v| v.parse().ok()).unwrap_or(20).min(100).max(1);
    let offset: i32 = params.get("offset").and_then(|v| v.parse().ok()).unwrap_or(0).max(0);

    let escaped = keyword.replace('%', "\\%").replace('_', "\\_");
    let pattern = format!("%{}%", escaped);

    let rows: Vec<(Uuid, String, Option<String>, String, i64, chrono::DateTime<chrono::Utc>)> = sqlx::query_as(
        "SELECT m.id, COALESCE(up.nickname, '?'), up.avatar, m.content, m.seq, m.created_at \
         FROM messages m \
         LEFT JOIN user_profiles up ON up.account_id = m.sender_id \
         WHERE m.conversation_id = $1 AND m.type = 0 AND m.sender_id != 0 AND m.content ILIKE $2 \
         ORDER BY m.created_at DESC \
         LIMIT $3 OFFSET $4"
    )
    .bind(conv_id).bind(&pattern).bind(limit).bind(offset)
    .fetch_all(service.db())
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let data: Vec<serde_json::Value> = rows.into_iter().map(|(id, name, avatar, content, seq, created_at)| {
        serde_json::json!({
            "message_id": id.to_string(),
            "sender_name": name,
            "sender_avatar": avatar,
            "content": content,
            "seq": seq,
            "created_at": created_at.to_rfc3339(),
        })
    }).collect();

    Ok(Json(serde_json::json!({ "data": data })))
}

pub fn router(service: Arc<MessageService>) -> Router {
    Router::new()
        .route("/conversations/{id}/messages", get(get_messages).post(send_message))
        .route("/conversations/{conv_id}/read-seq", get(get_read_seq))
        .route("/conversations/{conv_id}/messages/{msg_id}/read-status", get(get_read_status))
        .route("/api/messages/search", get(search_messages))
        .route("/conversations/{conv_id}/messages/search", get(search_conversation_messages))
        .with_state(service)
}
