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
}

impl WsBroadcaster {
    pub fn new(ws_state: Arc<WsState>) -> Self {
        Self { ws_state }
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

        // 给其他成员推送（含 unread_count=1 增量）
        let update_others = ConversationUpdate {
            conversation_id: conversation_id.to_string(),
            last_message_preview: preview.to_string(),
            last_message_at: now_ms,
            unread_count: 1,
        };
        let frame_others = WsFrame {
            r#type: WsFrameType::ConversationUpdate as i32,
            payload: update_others.encode_to_vec(),
        };
        let others: Vec<i64> = member_ids.iter().filter(|&&id| id != sender_id).copied().collect();
        self.ws_state.send_to_users(&others, frame_others.encode_to_vec()).await;

        // 给发送者推送（unread_count=0，仅更新预览）
        let update_sender = ConversationUpdate {
            conversation_id: conversation_id.to_string(),
            last_message_preview: preview.to_string(),
            last_message_at: now_ms,
            unread_count: 0,
        };
        let frame_sender = WsFrame {
            r#type: WsFrameType::ConversationUpdate as i32,
            payload: update_sender.encode_to_vec(),
        };
        self.ws_state.send_to_users(&[sender_id], frame_sender.encode_to_vec()).await;
    }
}
