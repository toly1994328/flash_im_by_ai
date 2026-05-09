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

    // ─── 转发相关 ───

    /// 按 ID 列表查询消息（转发用）
    pub async fn find_by_ids(&self, ids: &[Uuid], conv_id: Uuid) -> Result<Vec<Message>, sqlx::Error> {
        sqlx::query_as(
            "SELECT * FROM messages WHERE id = ANY($1) AND conversation_id = $2 AND status != 2"
        )
        .bind(ids)
        .bind(conv_id)
        .fetch_all(&self.pool)
        .await
    }

    // ─── 置顶相关 ───

    /// 插入置顶记录
    pub async fn insert_pin(&self, conv_id: Uuid, msg_id: Uuid, pinned_by: i64) -> Result<crate::models::PinnedMessage, sqlx::Error> {
        sqlx::query_as(
            "INSERT INTO pinned_messages (conversation_id, message_id, pinned_by) \
             VALUES ($1, $2, $3) RETURNING *"
        )
        .bind(conv_id)
        .bind(msg_id)
        .bind(pinned_by)
        .fetch_one(&self.pool)
        .await
    }

    /// 删除置顶记录
    pub async fn delete_pin(&self, pin_id: Uuid, conv_id: Uuid) -> Result<u64, sqlx::Error> {
        let result = sqlx::query(
            "DELETE FROM pinned_messages WHERE id = $1 AND conversation_id = $2"
        )
        .bind(pin_id)
        .bind(conv_id)
        .execute(&self.pool)
        .await?;
        Ok(result.rows_affected())
    }

    /// 查询会话置顶数量
    pub async fn count_pins(&self, conv_id: Uuid) -> Result<i64, sqlx::Error> {
        let (count,): (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM pinned_messages WHERE conversation_id = $1"
        )
        .bind(conv_id)
        .fetch_one(&self.pool)
        .await?;
        Ok(count)
    }

    /// 检查消息是否已置顶
    pub async fn is_pinned(&self, conv_id: Uuid, msg_id: Uuid) -> Result<bool, sqlx::Error> {
        let result: Option<(i32,)> = sqlx::query_as(
            "SELECT 1 FROM pinned_messages WHERE conversation_id = $1 AND message_id = $2"
        )
        .bind(conv_id)
        .bind(msg_id)
        .fetch_optional(&self.pool)
        .await?;
        Ok(result.is_some())
    }

    /// 查询置顶列表（带消息内容）
    pub async fn get_pinned_with_content(&self, conv_id: Uuid) -> Result<Vec<crate::models::PinnedMessageWithContent>, sqlx::Error> {
        sqlx::query_as(
            "SELECT p.id as pin_id, p.message_id, m.content, m.type as msg_type, \
                    COALESCE(up.nickname, '?') as sender_name, \
                    p.pinned_by, p.pinned_at \
             FROM pinned_messages p \
             JOIN messages m ON p.message_id = m.id \
             LEFT JOIN user_profiles up ON m.sender_id = up.account_id \
             WHERE p.conversation_id = $1 \
             ORDER BY p.pinned_at DESC"
        )
        .bind(conv_id)
        .fetch_all(&self.pool)
        .await
    }

    /// 按 ID 查询单条消息
    pub async fn find_by_id(&self, id: Uuid, conv_id: Uuid) -> Result<Option<Message>, sqlx::Error> {
        sqlx::query_as(
            "SELECT * FROM messages WHERE id = $1 AND conversation_id = $2"
        )
        .bind(id)
        .bind(conv_id)
        .fetch_optional(&self.pool)
        .await
    }
}
