use sqlx::PgPool;
use uuid::Uuid;

use super::models::{Conversation, ConversationListItem};

pub struct ConversationRepository {
    db: PgPool,
}

impl ConversationRepository {
    pub fn new(db: PgPool) -> Self {
        Self { db }
    }

    /// 查询两人之间是否已有私聊会话
    pub async fn find_private(
        &self,
        user_a: i64,
        user_b: i64,
    ) -> Result<Option<Conversation>, sqlx::Error> {
        sqlx::query_as::<_, Conversation>(
            "SELECT c.id, c.type, c.name, c.avatar, c.owner_id,
                    c.last_message_at, c.last_message_preview,
                    c.created_at, c.updated_at
             FROM conversations c
             JOIN conversation_members m1 ON m1.conversation_id = c.id AND m1.user_id = $1
             JOIN conversation_members m2 ON m2.conversation_id = c.id AND m2.user_id = $2
             WHERE c.type = 0"
        )
        .bind(user_a)
        .bind(user_b)
        .fetch_optional(&self.db)
        .await
    }

    /// 创建私聊会话（事务）
    pub async fn create_private(
        &self,
        user_a: i64,
        user_b: i64,
    ) -> Result<Conversation, sqlx::Error> {
        let mut tx = self.db.begin().await?;

        let conv = sqlx::query_as::<_, Conversation>(
            "INSERT INTO conversations (type) VALUES (0)
             RETURNING id, type, name, avatar, owner_id,
                       last_message_at, last_message_preview,
                       created_at, updated_at"
        )
        .fetch_one(&mut *tx)
        .await?;

        sqlx::query(
            "INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2)"
        )
        .bind(conv.id)
        .bind(user_a)
        .execute(&mut *tx)
        .await?;

        sqlx::query(
            "INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2)"
        )
        .bind(conv.id)
        .bind(user_b)
        .execute(&mut *tx)
        .await?;

        tx.commit().await?;
        Ok(conv)
    }

    /// 查询用户的会话列表（分页）
    pub async fn list_by_user(
        &self,
        user_id: i64,
        limit: i32,
        offset: i32,
    ) -> Result<Vec<ConversationListItem>, sqlx::Error> {
        sqlx::query_as::<_, ConversationListItem>(
            "SELECT c.id, c.type AS conv_type, c.name, c.avatar, c.owner_id,
                    c.last_message_at, c.last_message_preview,
                    c.created_at, c.updated_at,
                    cm.unread_count, cm.last_read_seq, cm.is_pinned, cm.is_muted,
                    peer.user_id AS peer_user_id
             FROM conversations c
             JOIN conversation_members cm ON cm.conversation_id = c.id AND cm.user_id = $1
             LEFT JOIN conversation_members peer ON peer.conversation_id = c.id
                       AND peer.user_id != $1 AND c.type = 0
             WHERE cm.is_deleted = false
             ORDER BY c.last_message_at DESC NULLS LAST, c.created_at DESC
             LIMIT $2 OFFSET $3"
        )
        .bind(user_id)
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.db)
        .await
    }

    /// 软删除会话
    pub async fn delete_for_user(
        &self,
        conversation_id: Uuid,
        user_id: i64,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query(
            "UPDATE conversation_members SET is_deleted = true
             WHERE conversation_id = $1 AND user_id = $2"
        )
        .bind(conversation_id)
        .bind(user_id)
        .execute(&self.db)
        .await?;

        Ok(result.rows_affected() > 0)
    }
}
