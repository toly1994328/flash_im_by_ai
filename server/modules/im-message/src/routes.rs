use axum::{
    Router, Json,
    extract::{Path, State, Query},
    http::{HeaderMap, StatusCode},
    routing::get,
};
use std::sync::Arc;
use uuid::Uuid;

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

pub fn router(service: Arc<MessageService>) -> Router {
    Router::new()
        .route("/conversations/{id}/messages", get(get_messages).post(send_message))
        .with_state(service)
}
