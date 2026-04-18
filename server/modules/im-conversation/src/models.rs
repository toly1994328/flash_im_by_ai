use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// 会话
#[derive(Debug, Clone, Serialize, FromRow)]
pub struct Conversation {
    pub id: Uuid,
    #[sqlx(rename = "type")]
    pub conv_type: i16,
    pub name: Option<String>,
    pub avatar: Option<String>,
    pub owner_id: Option<i64>,
    pub last_message_at: Option<DateTime<Utc>>,
    pub last_message_preview: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// 会话列表项（含对方信息和个人状态）
#[derive(Debug, Clone, Serialize, FromRow)]
pub struct ConversationListItem {
    pub id: Uuid,
    pub conv_type: i16,
    pub name: Option<String>,
    pub avatar: Option<String>,
    pub owner_id: Option<i64>,
    pub last_message_at: Option<DateTime<Utc>>,
    pub last_message_preview: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub unread_count: i32,
    pub last_read_seq: i64,
    pub peer_user_id: Option<i64>,
    pub is_pinned: bool,
    pub is_muted: bool,
}

/// 会话列表响应项（补充对方昵称头像）
#[derive(Debug, Clone, Serialize)]
pub struct ConversationListResponse {
    pub id: Uuid,
    pub conv_type: i16,
    pub name: Option<String>,
    pub avatar: Option<String>,
    pub peer_user_id: Option<String>,
    pub peer_nickname: Option<String>,
    pub peer_avatar: Option<String>,
    pub last_message_at: Option<DateTime<Utc>>,
    pub last_message_preview: Option<String>,
    pub unread_count: i32,
    pub is_pinned: bool,
    pub is_muted: bool,
    pub created_at: DateTime<Utc>,
}

/// 创建单聊请求
#[derive(Debug, Deserialize)]
pub struct CreatePrivateRequest {
    pub peer_user_id: i64,
}

/// 创建会话响应
#[derive(Debug, Serialize)]
pub struct CreateConversationResponse {
    pub id: Uuid,
    pub conv_type: i16,
    pub name: Option<String>,
    pub avatar: Option<String>,
    pub owner_id: Option<String>,
    pub peer_user_id: Option<String>,
    pub peer_nickname: Option<String>,
    pub peer_avatar: Option<String>,
    pub created_at: DateTime<Utc>,
}

/// 消息响应
#[derive(Debug, Serialize)]
pub struct MessageResponse {
    pub message: String,
}
