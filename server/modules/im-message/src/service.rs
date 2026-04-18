use std::sync::Arc;
use axum::http::StatusCode;
use sqlx::PgPool;
use uuid::Uuid;

use crate::broadcast::MessageBroadcaster;
use crate::models::{Message, MessageWithSender, NewMessage};
use crate::repository::MessageRepository;
use crate::seq::SeqGenerator;

pub struct MessageService {
    repo: MessageRepository,
    seq_gen: SeqGenerator,
    db: PgPool,
    broadcaster: Arc<dyn MessageBroadcaster>,
}

impl MessageService {
    pub fn new(db: PgPool, broadcaster: Arc<dyn MessageBroadcaster>) -> Self {
        Self {
            repo: MessageRepository::new(db.clone()),
            seq_gen: SeqGenerator::new(db.clone()),
            db,
            broadcaster,
        }
    }

    /// 发送消息（核心方法）
    pub async fn send(&self, msg: NewMessage) -> Result<Message, StatusCode> {
        if msg.content.trim().is_empty() {
            return Err(StatusCode::BAD_REQUEST);
        }

        // 验证是会话成员
        let is_member: Option<(i32,)> = sqlx::query_as(
            "SELECT 1 FROM conversation_members \
             WHERE conversation_id = $1 AND user_id = $2",
        )
        .bind(msg.conversation_id)
        .bind(msg.sender_id)
        .fetch_optional(&self.db)
        .await
        .map_err(|e| { println!("❌ [msg] is_member query failed: {}", e); StatusCode::INTERNAL_SERVER_ERROR })?;

        if is_member.is_none() {
            println!("❌ [msg] user {} is not member of {}", msg.sender_id, msg.conversation_id);
            return Err(StatusCode::FORBIDDEN);
        }

        // 生成序列号
        let seq = self.seq_gen.next(msg.conversation_id).await
            .map_err(|e| { println!("❌ [msg] seq gen failed: {}", e); StatusCode::INTERNAL_SERVER_ERROR })?;

        // 存储消息
        let message = self.repo.create(&msg, seq).await
            .map_err(|e| { println!("❌ [msg] create message failed: {}", e); StatusCode::INTERNAL_SERVER_ERROR })?;

        // 生成预览
        let preview = crate::models::generate_preview(&msg.content, msg.msg_type);

        // 更新会话最后消息
        let _ = sqlx::query(
            "UPDATE conversations SET last_message_preview = $2, \
             last_message_at = NOW(), updated_at = NOW() WHERE id = $1",
        )
        .bind(msg.conversation_id)
        .bind(&preview)
        .execute(&self.db)
        .await;

        // 给其他成员未读数 +1
        let _ = sqlx::query(
            "UPDATE conversation_members SET unread_count = unread_count + 1 \
             WHERE conversation_id = $1 AND user_id != $2 AND is_deleted = false",
        )
        .bind(msg.conversation_id)
        .bind(msg.sender_id)
        .execute(&self.db)
        .await;

        // 获取成员列表
        let member_rows: Vec<(i64,)> = sqlx::query_as(
            "SELECT user_id FROM conversation_members WHERE conversation_id = $1",
        )
        .bind(msg.conversation_id)
        .fetch_all(&self.db)
        .await
        .unwrap_or_default();
        let member_ids: Vec<i64> = member_rows.into_iter().map(|(id,)| id).collect();

        println!("📢 [msg] broadcasting to members: {:?}, sender: {}", member_ids, msg.sender_id);

        // 广播消息
        self.broadcaster.broadcast_message(&message, &member_ids, true).await;

        // 广播会话更新
        self.broadcaster.broadcast_conversation_update(
            msg.conversation_id, &preview, &member_ids, msg.sender_id,
        ).await;

        Ok(message)
    }

    /// 发送系统消息（跳过成员校验，sender_id=999999999）
    ///
    /// 走完整流程：seq → 存储 → 更新预览 → 广播
    pub async fn send_system(
        &self,
        conversation_id: Uuid,
        content: String,
    ) -> Result<Message, StatusCode> {
        const SYSTEM_USER_ID: i64 = 0;

        let msg = NewMessage {
            conversation_id,
            sender_id: SYSTEM_USER_ID,
            content,
            msg_type: 0,
            extra: None,
        };

        // 生成序列号
        let seq = self.seq_gen.next(conversation_id).await
            .map_err(|e| { println!("❌ [msg] seq gen failed: {}", e); StatusCode::INTERNAL_SERVER_ERROR })?;

        // 存储消息
        let message = self.repo.create(&msg, seq).await
            .map_err(|e| { println!("❌ [msg] create system message failed: {}", e); StatusCode::INTERNAL_SERVER_ERROR })?;

        // 生成预览
        let preview = crate::models::generate_preview(&msg.content, msg.msg_type);

        // 更新会话最后消息
        let _ = sqlx::query(
            "UPDATE conversations SET last_message_preview = $2, \
             last_message_at = NOW(), updated_at = NOW() WHERE id = $1",
        )
        .bind(conversation_id)
        .bind(&preview)
        .execute(&self.db)
        .await;

        // 获取成员列表
        let member_rows: Vec<(i64,)> = sqlx::query_as(
            "SELECT user_id FROM conversation_members WHERE conversation_id = $1",
        )
        .bind(conversation_id)
        .fetch_all(&self.db)
        .await
        .unwrap_or_default();
        let member_ids: Vec<i64> = member_rows.into_iter().map(|(id,)| id).collect();

        // 广播消息（不排除发送者，因为系统用户不在线）
        self.broadcaster.broadcast_message(&message, &member_ids, false).await;

        // 广播会话更新
        self.broadcaster.broadcast_conversation_update(
            conversation_id, &preview, &member_ids, SYSTEM_USER_ID,
        ).await;

        Ok(message)
    }

    /// 查询历史消息
    pub async fn get_history(
        &self,
        conversation_id: Uuid,
        before_seq: Option<i64>,
        limit: i32,
    ) -> Result<Vec<MessageWithSender>, StatusCode> {
        let limit = limit.min(100).max(1);
        let messages = match before_seq {
            Some(seq) => self.repo.find_before_with_sender(conversation_id, seq, limit).await,
            None => self.repo.find_latest_with_sender(conversation_id, limit).await,
        };
        messages.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)
    }
}
