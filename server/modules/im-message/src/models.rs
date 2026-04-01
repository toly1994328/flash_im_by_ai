use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// 消息
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Message {
    pub id: Uuid,
    pub conversation_id: Uuid,
    pub sender_id: i64,
    pub seq: i64,
    #[sqlx(rename = "type")]
    pub msg_type: i16,
    pub content: String,
    pub extra: Option<serde_json::Value>,
    pub status: i16,
    pub created_at: DateTime<Utc>,
}

/// 带发送者信息的消息（查询结果）
#[derive(Debug, Clone, Serialize, FromRow)]
pub struct MessageWithSender {
    pub id: Uuid,
    pub conversation_id: Uuid,
    pub sender_id: i64,
    pub sender_name: String,
    pub sender_avatar: Option<String>,
    pub seq: i64,
    pub msg_type: i16,
    pub content: String,
    pub extra: Option<serde_json::Value>,
    pub status: i16,
    pub created_at: DateTime<Utc>,
}

/// 创建消息用
pub struct NewMessage {
    pub conversation_id: Uuid,
    pub sender_id: i64,
    pub content: String,
}

/// 查询参数
#[derive(Debug, Deserialize)]
pub struct MessageQuery {
    pub before_seq: Option<i64>,
    #[serde(default = "default_limit")]
    pub limit: i32,
}

fn default_limit() -> i32 { 50 }
