//! 消息分发器

use std::sync::Arc;
use prost::Message as ProstMessage;
use uuid::Uuid;

use im_message::{MessageService, models::NewMessage};

use crate::proto::{MessageAck, SendMessageRequest, WsFrame, WsFrameType};
use crate::state::WsState;

pub struct MessageDispatcher {
    msg_service: Arc<MessageService>,
    ws_state: Arc<WsState>,
}

impl MessageDispatcher {
    pub fn new(msg_service: Arc<MessageService>, ws_state: Arc<WsState>) -> Self {
        Self { msg_service, ws_state }
    }

    pub async fn handle_chat_message(&self, sender_id: i64, payload: &[u8]) {
        let request = match SendMessageRequest::decode(payload) {
            Ok(r) => r,
            Err(e) => {
                println!("⚠️ [dispatcher] decode SendMessageRequest failed: {}", e);
                return;
            }
        };

        let conversation_id = match Uuid::parse_str(&request.conversation_id) {
            Ok(id) => id,
            Err(_) => return,
        };

        let new_msg = NewMessage {
            conversation_id,
            sender_id,
            content: request.content,
        };

        let message = match self.msg_service.send(new_msg).await {
            Ok(m) => m,
            Err(e) => {
                println!("⚠️ [dispatcher] send message failed: {:?}", e);
                return;
            }
        };

        // 发送 ACK 给发送者
        let ack = MessageAck {
            message_id: message.id.to_string(),
            seq: message.seq,
        };
        let ack_frame = WsFrame {
            r#type: WsFrameType::MessageAck as i32,
            payload: ack.encode_to_vec(),
        };
        self.ws_state.send_to_user(sender_id, ack_frame.encode_to_vec()).await;

        println!("📨 [dispatcher] message sent: conv={}, seq={}, from={}",
            message.conversation_id, message.seq, sender_id);
    }
}
