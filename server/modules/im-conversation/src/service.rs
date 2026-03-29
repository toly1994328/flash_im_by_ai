use axum::http::StatusCode;
use sqlx::PgPool;
use uuid::Uuid;

use super::models::{
    ConversationListResponse, CreateConversationResponse,
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
            peer_user_id: peer_user_id.to_string(),
            peer_nickname,
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
}
