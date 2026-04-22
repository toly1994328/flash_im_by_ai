use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize, Serializer};
use sqlx::FromRow;
use thiserror::Error;
use uuid::Uuid;

/// i64 序列化为字符串（JSON 中大整数安全）
fn id_as_string<S: Serializer>(val: &i64, s: S) -> Result<S::Ok, S::Error> {
    s.serialize_str(&val.to_string())
}

/// 好友申请状态
#[repr(i16)]
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum FriendRequestStatus {
    Pending = 0,
    Accepted = 1,
    Rejected = 2,
}

/// 好友申请
#[derive(Debug, Clone, Serialize, FromRow)]
pub struct FriendRequest {
    pub id: Uuid,
    #[serde(serialize_with = "id_as_string")]
    pub from_user_id: i64,
    #[serde(serialize_with = "id_as_string")]
    pub to_user_id: i64,
    pub message: Option<String>,
    pub status: i16,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// 好友关系
#[derive(Debug, Clone, Serialize, FromRow)]
pub struct FriendRelation {
    #[serde(serialize_with = "id_as_string")]
    pub user_id: i64,
    #[serde(serialize_with = "id_as_string")]
    pub friend_id: i64,
    pub created_at: DateTime<Utc>,
}

/// 带用户信息的好友（API 响应）
#[derive(Debug, Clone, Serialize, FromRow)]
pub struct FriendWithProfile {
    #[serde(serialize_with = "id_as_string")]
    pub friend_id: i64,
    pub nickname: String,
    pub avatar: Option<String>,
    pub bio: Option<String>,
    pub created_at: DateTime<Utc>,
}

/// 带用户信息的好友申请（API 响应）
#[derive(Debug, Clone, Serialize)]
pub struct FriendRequestWithProfile {
    #[serde(flatten)]
    pub request: FriendRequest,
    pub nickname: String,
    pub avatar: Option<String>,
}

/// 发送好友申请请求
#[derive(Debug, Deserialize)]
pub struct SendFriendRequestInput {
    pub to_user_id: i64,
    pub message: Option<String>,
}

/// 好友列表查询参数
#[derive(Debug, Deserialize)]
pub struct FriendListQuery {
    #[serde(default = "default_limit")]
    pub limit: i32,
    #[serde(default)]
    pub offset: i32,
}

fn default_limit() -> i32 { 1000 }

/// 好友服务错误
#[derive(Debug, Error)]
pub enum FriendError {
    #[error("用户不存在")]
    UserNotFound,
    #[error("申请不存在")]
    RequestNotFound,
    #[error("好友关系不存在")]
    RelationNotFound,
    #[error("已发送过申请")]
    AlreadyRequested,
    #[error("已经是好友")]
    AlreadyFriends,
    #[error("不能添加自己")]
    CannotAddSelf,
    #[error("无权操作")]
    Forbidden,
    #[error("数据库错误: {0}")]
    Database(#[from] sqlx::Error),
}

impl From<FriendError> for axum::http::StatusCode {
    fn from(e: FriendError) -> Self {
        match e {
            FriendError::UserNotFound => Self::NOT_FOUND,
            FriendError::RequestNotFound => Self::NOT_FOUND,
            FriendError::RelationNotFound => Self::NOT_FOUND,
            FriendError::AlreadyRequested => Self::BAD_REQUEST,
            FriendError::AlreadyFriends => Self::BAD_REQUEST,
            FriendError::CannotAddSelf => Self::BAD_REQUEST,
            FriendError::Forbidden => Self::FORBIDDEN,
            FriendError::Database(_) => Self::INTERNAL_SERVER_ERROR,
        }
    }
}
