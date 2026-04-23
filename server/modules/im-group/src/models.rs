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

// ─── v0.0.2：搜索加群与入群审批 ───

/// 搜索查询参数
#[derive(Debug, Deserialize)]
pub struct SearchQuery {
    pub keyword: Option<String>,
}

/// 入群申请请求
#[derive(Debug, Deserialize)]
pub struct JoinGroupRequest {
    pub message: Option<String>,
}

/// 入群审批请求
#[derive(Debug, Deserialize)]
pub struct HandleJoinRequest {
    pub approved: bool,
}

/// 群搜索结果项
#[derive(Debug, Serialize, FromRow)]
pub struct GroupSearchResult {
    pub id: Uuid,
    pub name: Option<String>,
    pub avatar: Option<String>,
    pub owner_id: Option<i64>,
    pub group_no: i64,
    pub member_count: i64,
    pub is_member: bool,
    pub join_verification: bool,
    pub has_pending_request: bool,
}

/// 入群申请列表项（群主视角）
#[derive(Debug, Serialize, FromRow)]
pub struct JoinRequestItem {
    pub id: Uuid,
    pub conversation_id: Uuid,
    pub group_name: Option<String>,
    pub group_avatar: Option<String>,
    pub user_id: i64,
    pub nickname: String,
    pub avatar: Option<String>,
    pub message: Option<String>,
    pub status: i16,
    pub created_at: DateTime<Utc>,
}

/// 入群响应
#[derive(Debug, Serialize)]
pub struct JoinGroupResponse {
    pub auto_approved: bool,
}

/// service 层入群结果枚举
pub enum JoinResult {
    AutoApproved,
    PendingApproval { request_id: Uuid, owner_id: i64 },
}

// ─── 群详情与群设置 ───

/// 群成员信息
#[derive(Debug, Serialize, FromRow)]
pub struct GroupMember {
    pub user_id: i64,
    pub nickname: String,
    pub avatar: Option<String>,
}

/// 群详情（群信息 + 成员列表）
#[derive(Debug, Serialize)]
pub struct GroupDetail {
    pub id: Uuid,
    pub name: Option<String>,
    pub avatar: Option<String>,
    pub owner_id: Option<i64>,
    pub group_no: i64,
    pub member_count: i64,
    pub join_verification: bool,
    pub members: Vec<GroupMember>,
    pub status: i16,
    pub announcement: Option<String>,
    pub announcement_updated_at: Option<DateTime<Utc>>,
}

/// 群设置请求
#[derive(Debug, Deserialize)]
pub struct UpdateGroupSettingsRequest {
    pub join_verification: Option<bool>,
}

// ─── v0.0.3：群成员管理 ───

/// 邀请入群请求
#[derive(Debug, Deserialize)]
pub struct AddMembersRequest {
    pub member_ids: Vec<i64>,
}

/// 转让群主请求
#[derive(Debug, Deserialize)]
pub struct TransferOwnerRequest {
    pub new_owner_id: i64,
}

/// 修改群信息请求
#[derive(Debug, Deserialize)]
pub struct UpdateGroupRequest {
    pub name: Option<String>,
    pub avatar: Option<String>,
}

/// 群公告请求
#[derive(Debug, Deserialize)]
pub struct UpdateAnnouncementRequest {
    pub announcement: String,
}
