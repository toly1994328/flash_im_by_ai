use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

/// 创建群聊请求
#[derive(Debug, Deserialize)]
pub struct CreateGroupRequest {
    pub name: String,
    pub member_ids: Vec<i64>,
}

/// 群聊信息（创建群聊返回）
#[derive(Debug, Clone, Serialize, FromRow)]
pub struct GroupConversation {
    pub id: Uuid,
    #[sqlx(rename = "type")]
    pub conv_type: i16,
    pub name: Option<String>,
    pub avatar: Option<String>,
    pub owner_id: Option<i64>,
    pub created_at: DateTime<Utc>,
}
