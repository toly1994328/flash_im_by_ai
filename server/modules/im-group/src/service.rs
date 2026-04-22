use axum::http::StatusCode;
use flash_core::AppError;
use sqlx::PgPool;
use uuid::Uuid;

use super::models::{GroupConversation, GroupSearchResult, JoinRequestItem, JoinResult, GroupDetail};
use super::repository::GroupRepository;

pub struct GroupService {
    repo: GroupRepository,
    db: PgPool,
}

impl GroupService {
    pub fn new(db: PgPool) -> Self {
        let repo = GroupRepository::new(db.clone());
        Self { repo, db }
    }

    pub fn db(&self) -> &PgPool {
        &self.db
    }

    pub fn repo(&self) -> &GroupRepository {
        &self.repo
    }

    /// 创建群聊
    pub async fn create_group(
        &self,
        owner_id: i64,
        name: &str,
        member_ids: &[i64],
    ) -> Result<GroupConversation, StatusCode> {
        let name = name.trim();
        if name.is_empty() {
            return Err(StatusCode::BAD_REQUEST);
        }

        // 去重，排除群主
        let unique_members: Vec<i64> = member_ids.iter()
            .copied()
            .filter(|&id| id != owner_id)
            .collect::<std::collections::HashSet<_>>()
            .into_iter()
            .collect();

        // 加上群主至少 3 人
        if unique_members.len() < 2 {
            return Err(StatusCode::BAD_REQUEST);
        }
        if unique_members.len() + 1 > 200 {
            return Err(StatusCode::BAD_REQUEST);
        }

        self.repo.create_group(name, owner_id, &unique_members)
            .await
            .map_err(|e| {
                println!("❌ [group] create_group failed: {}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })
    }

    // ─── v0.0.2：搜索加群与入群审批 ───

    /// 搜索群聊
    pub async fn search_groups(
        &self,
        user_id: i64,
        keyword: &str,
    ) -> Result<Vec<GroupSearchResult>, StatusCode> {
        let keyword = keyword.trim();
        if keyword.is_empty() {
            return Ok(vec![]);
        }

        let is_numeric = keyword.parse::<i64>().is_ok();

        self.repo.search_groups(user_id, keyword, is_numeric)
            .await
            .map_err(|e| {
                println!("❌ [group] search_groups failed: {}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })
    }

    /// 申请入群
    pub async fn join_group(
        &self,
        user_id: i64,
        conversation_id: Uuid,
        message: Option<&str>,
    ) -> Result<JoinResult, StatusCode> {
        // 校验群存在
        let owner_id = self.repo.get_group_owner(conversation_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .ok_or(StatusCode::NOT_FOUND)?;

        // 校验非成员
        let is_member = self.repo.is_member(conversation_id, user_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        if is_member {
            return Err(StatusCode::BAD_REQUEST); // 已经是群成员
        }

        // 校验无待处理申请
        let pending = self.repo.find_pending_request(conversation_id, user_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        if pending.is_some() {
            return Err(StatusCode::BAD_REQUEST); // 已有待处理的入群申请
        }

        // 查 join_verification
        let need_verification = self.repo.get_join_verification(conversation_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        if !need_verification {
            // 无需验证，直接加入
            self.repo.join_group_direct(conversation_id, user_id)
                .await
                .map_err(|e| {
                    println!("❌ [group] join_group_direct failed: {}", e);
                    StatusCode::INTERNAL_SERVER_ERROR
                })?;
            Ok(JoinResult::AutoApproved)
        } else {
            // 需要验证，创建申请
            let request_id = self.repo.create_join_request(conversation_id, user_id, message)
                .await
                .map_err(|e| {
                    println!("❌ [group] create_join_request failed: {}", e);
                    StatusCode::INTERNAL_SERVER_ERROR
                })?;
            Ok(JoinResult::PendingApproval { request_id, owner_id })
        }
    }

    /// 群主审批入群申请
    /// 返回 Some(applicant_user_id) 表示同意，None 表示拒绝
    pub async fn handle_join_request(
        &self,
        owner_id: i64,
        conversation_id: Uuid,
        request_id: Uuid,
        approved: bool,
    ) -> Result<Option<i64>, StatusCode> {
        // 校验当前用户是群主
        let actual_owner = self.repo.get_group_owner(conversation_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .ok_or(StatusCode::NOT_FOUND)?;

        if actual_owner != owner_id {
            return Err(StatusCode::FORBIDDEN);
        }

        // 校验申请存在且 status=0
        let (req_conv_id, applicant_id, status) = self.repo.get_join_request(request_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .ok_or(StatusCode::NOT_FOUND)?;

        if req_conv_id != conversation_id {
            return Err(StatusCode::BAD_REQUEST);
        }

        if status != 0 {
            return Err(StatusCode::BAD_REQUEST); // 该申请已处理
        }

        if approved {
            self.repo.update_join_request_status(request_id, 1)
                .await
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
            self.repo.join_group_direct(conversation_id, applicant_id)
                .await
                .map_err(|e| {
                    println!("❌ [group] join after approval failed: {}", e);
                    StatusCode::INTERNAL_SERVER_ERROR
                })?;
            Ok(Some(applicant_id))
        } else {
            self.repo.update_join_request_status(request_id, 2)
                .await
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
            Ok(None)
        }
    }

    /// 查询入群申请列表（群主视角）
    pub async fn list_join_requests(
        &self,
        owner_id: i64,
    ) -> Result<Vec<JoinRequestItem>, StatusCode> {
        self.repo.list_join_requests(owner_id)
            .await
            .map_err(|e| {
                println!("❌ [group] list_join_requests failed: {}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })
    }

    // ─── 群详情与群设置 ───

    /// 获取群详情
    pub async fn get_group_detail(
        &self,
        user_id: i64,
        conversation_id: Uuid,
    ) -> Result<GroupDetail, StatusCode> {
        // 校验是群成员
        let is_member = self.repo.is_member(conversation_id, user_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        if !is_member {
            return Err(StatusCode::FORBIDDEN);
        }

        // 查群信息
        let (name, avatar, owner_id, group_no, join_verification, status, announcement, announcement_updated_at) = self.repo
            .get_group_info(conversation_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .ok_or(StatusCode::NOT_FOUND)?;

        // 查成员列表
        let members = self.repo.get_group_members(conversation_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        Ok(GroupDetail {
            id: conversation_id,
            name,
            avatar,
            owner_id,
            group_no,
            member_count: members.len() as i64,
            join_verification,
            members,
            status,
            announcement,
            announcement_updated_at,
        })
    }

    /// 群主修改群设置
    pub async fn update_group_settings(
        &self,
        user_id: i64,
        conversation_id: Uuid,
        join_verification: bool,
    ) -> Result<(), StatusCode> {
        // 校验是群主
        let owner_id = self.repo.get_group_owner(conversation_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .ok_or(StatusCode::NOT_FOUND)?;

        if owner_id != user_id {
            return Err(StatusCode::FORBIDDEN);
        }

        self.repo.update_group_settings(conversation_id, join_verification)
            .await
            .map_err(|e| {
                println!("❌ [group] update_group_settings failed: {}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })
    }

    // ─── v0.0.3：群成员管理 ───

    /// 邀请入群
    pub async fn add_members(
        &self,
        user_id: i64,
        conversation_id: Uuid,
        member_ids: &[i64],
    ) -> Result<usize, AppError> {
        // 校验当前用户是群成员
        let is_member = self.repo.is_member(conversation_id, user_id).await?;
        if !is_member {
            return Err(AppError::forbidden("非群成员，无权邀请"));
        }

        // 校验群未解散
        let status = self.repo.get_conversation_status(conversation_id).await?;
        if status == 1 {
            return Err(AppError::forbidden("群聊已解散"));
        }

        // 校验不超过 max_members (200)
        let current_count = self.repo.get_member_count(conversation_id).await?;
        if current_count + member_ids.len() as i64 > 200 {
            return Err(AppError::bad_request("超过群成员上限"));
        }

        let added = self.repo.add_members(conversation_id, member_ids).await?;
        Ok(added)
    }

    /// 踢人
    pub async fn remove_member(
        &self,
        user_id: i64,
        conversation_id: Uuid,
        target_id: i64,
    ) -> Result<(), StatusCode> {
        // 校验当前用户是群主
        let owner_id = self.repo.get_group_owner(conversation_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .ok_or(StatusCode::NOT_FOUND)?;
        if owner_id != user_id {
            return Err(StatusCode::FORBIDDEN);
        }

        // 不能踢群主自己
        if target_id == owner_id {
            return Err(StatusCode::BAD_REQUEST);
        }

        // 校验 target 是群成员
        let is_member = self.repo.is_member(conversation_id, target_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        if !is_member {
            return Err(StatusCode::BAD_REQUEST);
        }

        self.repo.remove_member(conversation_id, target_id)
            .await
            .map_err(|e| {
                println!("❌ [group] remove_member failed: {}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })
    }

    /// 退群
    pub async fn leave(
        &self,
        user_id: i64,
        conversation_id: Uuid,
    ) -> Result<(), StatusCode> {
        // 校验当前用户是群成员
        let is_member = self.repo.is_member(conversation_id, user_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        if !is_member {
            return Err(StatusCode::BAD_REQUEST);
        }

        // 群主不能退出
        let owner_id = self.repo.get_group_owner(conversation_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .ok_or(StatusCode::NOT_FOUND)?;
        if owner_id == user_id {
            return Err(StatusCode::BAD_REQUEST);
        }

        self.repo.remove_member(conversation_id, user_id)
            .await
            .map_err(|e| {
                println!("❌ [group] leave failed: {}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })
    }

    /// 转让群主
    pub async fn transfer_owner(
        &self,
        user_id: i64,
        conversation_id: Uuid,
        new_owner_id: i64,
    ) -> Result<(), StatusCode> {
        // 校验当前用户是群主
        let owner_id = self.repo.get_group_owner(conversation_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .ok_or(StatusCode::NOT_FOUND)?;
        if owner_id != user_id {
            return Err(StatusCode::FORBIDDEN);
        }

        // 校验新群主是群成员
        let is_member = self.repo.is_member(conversation_id, new_owner_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        if !is_member {
            return Err(StatusCode::BAD_REQUEST);
        }

        self.repo.transfer_owner(conversation_id, new_owner_id)
            .await
            .map_err(|e| {
                println!("❌ [group] transfer_owner failed: {}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })
    }

    /// 解散群聊
    pub async fn disband(
        &self,
        user_id: i64,
        conversation_id: Uuid,
    ) -> Result<(), StatusCode> {
        // 校验当前用户是群主
        let owner_id = self.repo.get_group_owner(conversation_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .ok_or(StatusCode::NOT_FOUND)?;
        if owner_id != user_id {
            return Err(StatusCode::FORBIDDEN);
        }

        self.repo.disband(conversation_id)
            .await
            .map_err(|e| {
                println!("❌ [group] disband failed: {}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })
    }

    /// 更新群公告
    pub async fn update_announcement(
        &self,
        user_id: i64,
        conversation_id: Uuid,
        announcement: &str,
    ) -> Result<(), StatusCode> {
        // 校验当前用户是群主
        let owner_id = self.repo.get_group_owner(conversation_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .ok_or(StatusCode::NOT_FOUND)?;
        if owner_id != user_id {
            return Err(StatusCode::FORBIDDEN);
        }

        self.repo.update_announcement(conversation_id, announcement, user_id)
            .await
            .map_err(|e| {
                println!("❌ [group] update_announcement failed: {}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })
    }

    /// 修改群信息（群名/头像）
    pub async fn update_group(
        &self,
        user_id: i64,
        conversation_id: Uuid,
        name: Option<&str>,
        avatar: Option<&str>,
    ) -> Result<(), StatusCode> {
        // 校验当前用户是群主
        let owner_id = self.repo.get_group_owner(conversation_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .ok_or(StatusCode::NOT_FOUND)?;
        if owner_id != user_id {
            return Err(StatusCode::FORBIDDEN);
        }

        // 如果传了 name，trim 后校验非空
        if let Some(n) = name {
            if n.trim().is_empty() {
                return Err(StatusCode::BAD_REQUEST);
            }
        }

        self.repo.update_group(conversation_id, name, avatar)
            .await
            .map_err(|e| {
                println!("❌ [group] update_group failed: {}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })
    }
}
