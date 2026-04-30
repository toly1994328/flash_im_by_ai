use sqlx::PgPool;
use uuid::Uuid;

use crate::models::{Message, MessageWithSender, NewMessage};

pub struct MessageRepository {
    pool: PgPool,
}

impl MessageRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn create(&self, msg: &NewMessage, seq: i64) -> Result<Message, sqlx::Error> {
        sqlx::query_as(
            "INSERT INTO messages (conversation_id, sender_id, seq, type, content, extra) \
             VALUES ($1, $2, $3, $4, $5, $6) RETURNING *",
        )
        .bind(msg.conversation_id)
        .bind(msg.sender_id)
        .bind(seq)
        .bind(msg.msg_type)
        .bind(&msg.content)
        .bind(&msg.extra)
        .fetch_one(&self.pool)
        .await
    }

    pub async fn find_before_with_sender(
        &self,
        conversation_id: Uuid,
        before_seq: i64,
        limit: i32,
    ) -> Result<Vec<MessageWithSender>, sqlx::Error> {
        sqlx::query_as(
            "SELECT m.id, m.conversation_id, m.sender_id, \
                    COALESCE(p.nickname, '?') as sender_name, \
                    p.avatar as sender_avatar, \
                    m.seq, m.type as msg_type, m.content, m.extra, m.status, m.created_at \
             FROM messages m \
             LEFT JOIN user_profiles p ON m.sender_id = p.account_id \
             WHERE m.conversation_id = $1 AND m.seq < $2 AND m.status != 2 \
             ORDER BY m.seq DESC LIMIT $3",
        )
        .bind(conversation_id)
        .bind(before_seq)
        .bind(limit)
        .fetch_all(&self.pool)
        .await
    }

    pub async fn find_after_with_sender(
        &self,
        conversation_id: Uuid,
        after_seq: i64,
        limit: i32,
    ) -> Result<Vec<MessageWithSender>, sqlx::Error> {
        sqlx::query_as(
            "SELECT m.id, m.conversation_id, m.sender_id, \
                    COALESCE(p.nickname, '?') as sender_name, \
                    p.avatar as sender_avatar, \
                    m.seq, m.type as msg_type, m.content, m.extra, m.status, m.created_at \
             FROM messages m \
             LEFT JOIN user_profiles p ON m.sender_id = p.account_id \
             WHERE m.conversation_id = $1 AND m.seq > $2 AND m.status != 2 \
             ORDER BY m.seq ASC LIMIT $3",
        )
        .bind(conversation_id)
        .bind(after_seq)
        .bind(limit)
        .fetch_all(&self.pool)
        .await
    }

    pub async fn find_latest_with_sender(
        &self,
        conversation_id: Uuid,
        limit: i32,
    ) -> Result<Vec<MessageWithSender>, sqlx::Error> {
        sqlx::query_as(
            "SELECT m.id, m.conversation_id, m.sender_id, \
                    COALESCE(p.nickname, '?') as sender_name, \
                    p.avatar as sender_avatar, \
                    m.seq, m.type as msg_type, m.content, m.extra, m.status, m.created_at \
             FROM messages m \
             LEFT JOIN user_profiles p ON m.sender_id = p.account_id \
             WHERE m.conversation_id = $1 AND m.status != 2 \
             ORDER BY m.seq DESC LIMIT $2",
        )
        .bind(conversation_id)
        .bind(limit)
        .fetch_all(&self.pool)
        .await
    }
}
