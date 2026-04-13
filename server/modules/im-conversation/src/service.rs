use axum::http::StatusCode;
use sqlx::PgPool;
use uuid::Uuid;

use super::models::{
    ConversationListItem, ConversationListResponse, CreateConversationResponse,
    GroupSearchResult, JoinGroupResponse, MyJoinRequestItem,
};
use super::repository::ConversationRepository;

pub struct ConversationService {
    repo: ConversationRepository,
    db: PgPool,
}

impl ConversationService {
    pub fn new(db: PgPool) -> Self {
        let repo = ConversationRepository::new(db.clone());
        Self { repo, db }
    }

    /// 获取数据库连接池引用（供 routes 层查询用户信息）
    pub fn db(&self) -> &PgPool {
        &self.db
    }

    /// 创建私聊（幂等）
    pub async fn create_private(
        &self,
        user_id: i64,
        peer_user_id: i64,
    ) -> Result<CreateConversationResponse, StatusCode> {
        if user_id == peer_user_id {
            return Err(StatusCode::BAD_REQUEST);
        }

        // 校验对方存在
        let peer: Option<(i64, String, Option<String>)> = sqlx::query_as(
            "SELECT p.account_id, p.nickname, p.avatar
             FROM user_profiles p JOIN accounts a ON a.id = p.account_id
             WHERE p.account_id = $1 AND a.status = 0"
        )
        .bind(peer_user_id)
        .fetch_optional(&self.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        let (_, peer_nickname, peer_avatar) = peer.ok_or(StatusCode::NOT_FOUND)?;

        // 查找已有会话
        let existing = self.repo.find_private(user_id, peer_user_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        let conv = match existing {
            Some(c) => c,
            None => self.repo.create_private(user_id, peer_user_id)
                .await
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?,
        };

        Ok(CreateConversationResponse {
            id: conv.id,
            conv_type: conv.conv_type,
            name: Some(peer_nickname.clone()),
            avatar: peer_avatar.clone(),
            owner_id: None,
            peer_user_id: Some(peer_user_id.to_string()),
            peer_nickname: Some(peer_nickname),
            peer_avatar,
            created_at: conv.created_at,
        })
    }

    /// 获取会话列表（单聊补充对方昵称头像，分页）
    pub async fn get_list(
        &self,
        user_id: i64,
        limit: i32,
        offset: i32,
    ) -> Result<Vec<ConversationListResponse>, StatusCode> {
        let items = self.repo.list_by_user(user_id, limit, offset)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        let mut result = Vec::with_capacity(items.len());
        for item in items {
            let (peer_nickname, peer_avatar) = if item.conv_type == 0 {
                if let Some(peer_id) = item.peer_user_id {
                    let profile: Option<(String, Option<String>)> = sqlx::query_as(
                        "SELECT nickname, avatar FROM user_profiles WHERE account_id = $1"
                    )
                    .bind(peer_id)
                    .fetch_optional(&self.db)
                    .await
                    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

                    profile.unwrap_or(("未知用户".to_string(), None))
                } else {
                    ("未知用户".to_string(), None)
                }
            } else {
                (String::new(), None)
            };

            result.push(ConversationListResponse {
                id: item.id,
                conv_type: item.conv_type,
                name: if item.conv_type == 0 { Some(peer_nickname.clone()) } else { item.name },
                avatar: if item.conv_type == 0 { peer_avatar.clone() } else { item.avatar },
                peer_user_id: item.peer_user_id.map(|id| id.to_string()),
                peer_nickname: if item.conv_type == 0 { Some(peer_nickname) } else { None },
                peer_avatar,
                last_message_at: item.last_message_at,
                last_message_preview: item.last_message_preview,
                unread_count: item.unread_count,
                is_pinned: item.is_pinned,
                is_muted: item.is_muted,
                created_at: item.created_at,
            });
        }

        Ok(result)
    }

    /// 删除会话
    pub async fn delete_for_user(
        &self,
        conversation_id: Uuid,
        user_id: i64,
    ) -> Result<(), StatusCode> {
        let deleted = self.repo.delete_for_user(conversation_id, user_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        if !deleted {
            return Err(StatusCode::NOT_FOUND);
        }
        Ok(())
    }

    /// 更新会话最后消息预览和时间
    pub async fn update_last_message(
        &self,
        conversation_id: Uuid,
        preview: &str,
    ) -> Result<(), StatusCode> {
        sqlx::query(
            "UPDATE conversations SET last_message_preview = $2, \
             last_message_at = NOW(), updated_at = NOW() WHERE id = $1",
        )
        .bind(conversation_id)
        .bind(preview)
        .execute(&self.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        Ok(())
    }

    /// 给其他成员未读数 +1
    pub async fn increment_unread(
        &self,
        conversation_id: Uuid,
        sender_id: i64,
    ) -> Result<(), StatusCode> {
        sqlx::query(
            "UPDATE conversation_members SET unread_count = unread_count + 1 \
             WHERE conversation_id = $1 AND user_id != $2 AND is_deleted = false",
        )
        .bind(conversation_id)
        .bind(sender_id)
        .execute(&self.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        Ok(())
    }

    /// 获取会话成员 ID 列表
    pub async fn get_member_ids(
        &self,
        conversation_id: Uuid,
    ) -> Result<Vec<i64>, StatusCode> {
        let rows: Vec<(i64,)> = sqlx::query_as(
            "SELECT user_id FROM conversation_members WHERE conversation_id = $1",
        )
        .bind(conversation_id)
        .fetch_all(&self.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        Ok(rows.into_iter().map(|(id,)| id).collect())
    }

    /// 获取单个会话详情
    pub async fn get_by_id(
        &self,
        conversation_id: Uuid,
        user_id: i64,
    ) -> Result<ConversationListResponse, StatusCode> {
        // 验证成员身份
        if !self.is_member(conversation_id, user_id).await? {
            return Err(StatusCode::FORBIDDEN);
        }

        let item: ConversationListItem = sqlx::query_as(
            "SELECT c.id, c.type AS conv_type, c.name, c.avatar, c.owner_id,
                    c.last_message_at, c.last_message_preview,
                    c.created_at, c.updated_at,
                    cm.unread_count, cm.last_read_seq, cm.is_pinned, cm.is_muted,
                    peer.user_id AS peer_user_id
             FROM conversations c
             JOIN conversation_members cm ON cm.conversation_id = c.id AND cm.user_id = $2
             LEFT JOIN conversation_members peer ON peer.conversation_id = c.id
                       AND peer.user_id != $2 AND c.type = 0
             WHERE c.id = $1 AND cm.is_deleted = false"
        )
        .bind(conversation_id)
        .bind(user_id)
        .fetch_optional(&self.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;

        let (peer_nickname, peer_avatar) = if item.conv_type == 0 {
            if let Some(peer_id) = item.peer_user_id {
                let profile: Option<(String, Option<String>)> = sqlx::query_as(
                    "SELECT nickname, avatar FROM user_profiles WHERE account_id = $1"
                )
                .bind(peer_id)
                .fetch_optional(&self.db)
                .await
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
                profile.unwrap_or(("未知用户".to_string(), None))
            } else {
                ("未知用户".to_string(), None)
            }
        } else {
            (String::new(), None)
        };

        Ok(ConversationListResponse {
            id: item.id,
            conv_type: item.conv_type,
            name: if item.conv_type == 0 { Some(peer_nickname.clone()) } else { item.name },
            avatar: if item.conv_type == 0 { peer_avatar.clone() } else { item.avatar },
            peer_user_id: item.peer_user_id.map(|id: i64| id.to_string()),
            peer_nickname: if item.conv_type == 0 { Some(peer_nickname) } else { None },
            peer_avatar,
            last_message_at: item.last_message_at,
            last_message_preview: item.last_message_preview,
            unread_count: item.unread_count,
            is_pinned: item.is_pinned,
            is_muted: item.is_muted,
            created_at: item.created_at,
        })
    }

    /// 检查用户是否是会話成員
    pub async fn is_member(
        &self,
        conversation_id: Uuid,
        user_id: i64,
    ) -> Result<bool, StatusCode> {
        let row: Option<(i32,)> = sqlx::query_as(
            "SELECT 1 FROM conversation_members \
             WHERE conversation_id = $1 AND user_id = $2",
        )
        .bind(conversation_id)
        .bind(user_id)
        .fetch_optional(&self.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        Ok(row.is_some())
    }

    // ==================== 群聊 ====================

    /// 创建群聊
    pub async fn create_group(
        &self,
        owner_id: i64,
        name: &str,
        member_ids: &[i64],
    ) -> Result<CreateConversationResponse, StatusCode> {
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

        let conv = self.repo.create_group(name, owner_id, &unique_members)
            .await
            .map_err(|e| {
                println!("❌ [conv] create_group failed: {}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })?;

        Ok(CreateConversationResponse {
            id: conv.id,
            conv_type: conv.conv_type,
            name: conv.name,
            avatar: conv.avatar,
            owner_id: conv.owner_id.map(|id| id.to_string()),
            peer_user_id: None,
            peer_nickname: None,
            peer_avatar: None,
            created_at: conv.created_at,
        })
    }

    /// 搜索群聊
    pub async fn search_groups(
        &self,
        keyword: &str,
        user_id: i64,
        limit: i32,
    ) -> Result<Vec<GroupSearchResult>, StatusCode> {
        if keyword.trim().is_empty() {
            return Ok(vec![]);
        }
        self.repo.search_groups(keyword, user_id, limit)
            .await
            .map_err(|e| {
                println!("❌ [conv] search_groups failed: {}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })
    }

    /// 申请入群
    pub async fn request_join(
        &self,
        user_id: i64,
        conversation_id: Uuid,
        message: Option<&str>,
    ) -> Result<JoinGroupResponse, StatusCode> {
        // 校验群存在且 type=1
        let conv = self.repo.find_by_id(conversation_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .ok_or(StatusCode::NOT_FOUND)?;

        if conv.conv_type != 1 {
            return Err(StatusCode::NOT_FOUND);
        }

        // 校验非成员
        if self.repo.is_member(conversation_id, user_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        {
            return Err(StatusCode::BAD_REQUEST); // 已经是群成员
        }

        // 校验无待处理申请
        if self.repo.find_pending_join_request(user_id, conversation_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .is_some()
        {
            return Err(StatusCode::BAD_REQUEST); // 已发送过入群申请
        }

        // 查询是否需要验证
        let need_verification = self.repo.get_group_join_verification(conversation_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        if !need_verification {
            // 直接加入
            self.repo.add_member(conversation_id, user_id)
                .await
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

            // 刷新宫格头像
            let avatar = self.repo.build_grid_avatar(conversation_id)
                .await
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
            let _ = sqlx::query("UPDATE conversations SET avatar = $2 WHERE id = $1")
                .bind(conversation_id)
                .bind(&avatar)
                .execute(&self.db)
                .await;

            Ok(JoinGroupResponse {
                auto_approved: true,
                owner_id: None,
                group_name: None,
            })
        } else {
            // 创建申请
            let _ = self.repo.create_join_request(user_id, conversation_id, message)
                .await
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

            Ok(JoinGroupResponse {
                auto_approved: false,
                owner_id: conv.owner_id.map(|id| id.to_string()),
                group_name: conv.name,
            })
        }
    }

    /// 处理入群申请
    pub async fn handle_join_request(
        &self,
        request_id: Uuid,
        handler_id: i64,
        approved: bool,
    ) -> Result<(), StatusCode> {
        let request = self.repo.find_join_request_by_id(request_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .ok_or(StatusCode::NOT_FOUND)?;

        if request.status != 0 {
            return Err(StatusCode::BAD_REQUEST);
        }

        // 校验是群主
        let conv = self.repo.find_by_id(request.conversation_id)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .ok_or(StatusCode::NOT_FOUND)?;

        if conv.owner_id != Some(handler_id) {
            return Err(StatusCode::FORBIDDEN);
        }

        if approved {
            self.repo.update_join_request_status(request_id, 1, handler_id)
                .await
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

            self.repo.add_member(request.conversation_id, request.user_id)
                .await
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

            // 刷新宫格头像
            let avatar = self.repo.build_grid_avatar(request.conversation_id)
                .await
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
            let _ = sqlx::query("UPDATE conversations SET avatar = $2 WHERE id = $1")
                .bind(request.conversation_id)
                .bind(&avatar)
                .execute(&self.db)
                .await;
        } else {
            self.repo.update_join_request_status(request_id, 2, handler_id)
                .await
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        }

        Ok(())
    }

    /// 获取我的群通知（作为群主的待处理入群申请）
    pub async fn get_my_join_requests(
        &self,
        user_id: i64,
        limit: i32,
        offset: i32,
    ) -> Result<Vec<MyJoinRequestItem>, StatusCode> {
        self.repo.get_my_pending_join_requests(user_id, limit, offset)
            .await
            .map_err(|e| {
                println!("❌ [conv] get_my_join_requests failed: {}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })
    }
}
