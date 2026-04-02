//! WebSocket 广播器实现

use std::sync::Arc;
use async_trait::async_trait;
use prost::Message as ProstMessage;
use uuid::Uuid;

use im_message::{MessageBroadcaster, models::Message};

use crate::proto::{ChatMessage, ConversationUpdate, WsFrame, WsFrameType};
use crate::state::WsState;

pub struct WsBroadcaster {
    ws_state: Arc<WsState>,
    db: sqlx::PgPool,
}

impl WsBroadcaster {
    pub fn new(ws_state: Arc<WsState>, db: sqlx::PgPool) -> Self {
        Self { ws_state, db }
    }
}

#[async_trait]
impl MessageBroadcaster for WsBroadcaster {
    async fn broadcast_message(
        &self,
        message: &Message,
        member_ids: &[i64],
        exclude_sender: bool,
    ) {
        let chat_msg = ChatMessage {
            id: message.id.to_string(),
            conversation_id: message.conversation_id.to_string(),
            sender_id: message.sender_id.to_string(),
            seq: message.seq,
            r#type: message.msg_type as i32,
            content: message.content.clone(),
            extra: vec![],
            status: 0,
            created_at: message.created_at.timestamp_millis(),
        };

        let frame = WsFrame {
            r#type: WsFrameType::ChatMessage as i32,
            payload: chat_msg.encode_to_vec(),
        };
        let data = frame.encode_to_vec();

        // 广播给除发送者外的成员
        let targets: Vec<i64> = if exclude_sender {
            member_ids.iter().filter(|&&id| id != message.sender_id).copied().collect()
        } else {
            member_ids.to_vec()
        };
        println!("📢 [broadcaster] sending ChatMessage to {:?}", targets);
        self.ws_state.send_to_users(&targets, data).await;
    }

    async fn broadcast_conversation_update(
        &self,
        conversation_id: Uuid,
        preview: &str,
        member_ids: &[i64],
        sender_id: i64,
    ) {
        let now_ms = chrono::Utc::now().timestamp_millis();

        // 给每个成员推送（各自的 total_unread 不同）
        for &uid in member_ids {
            let unread = if uid == sender_id { 0 } else { 1 };

            // 查询该用户的总未读数
            let total: i32 = sqlx::query_as::<_, (i64,)>(
                "SELECT COALESCE(SUM(unread_count), 0) FROM conversation_members \
                 WHERE user_id = $1 AND is_deleted = false"
            )
            .bind(uid)
            .fetch_one(&self.db)
            .await
            .map(|(n,)| n as i32)
            .unwrap_or(0);

            let update = ConversationUpdate {
                conversation_id: conversation_id.to_string(),
                last_message_preview: preview.to_string(),
                last_message_at: now_ms,
                unread_count: unread,
                total_unread: total,
            };
            let frame = WsFrame {
                r#type: WsFrameType::ConversationUpdate as i32,
                payload: update.encode_to_vec(),
            };
            self.ws_state.send_to_user(uid, frame.encode_to_vec()).await;
        }
    }
}
