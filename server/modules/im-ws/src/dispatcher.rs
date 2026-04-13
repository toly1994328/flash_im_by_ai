//! 消息分发器

use std::sync::Arc;
use prost::Message as ProstMessage;
use uuid::Uuid;

use im_message::{MessageService, models::NewMessage};

use crate::proto::{
    MessageAck, SendMessageRequest, WsFrame, WsFrameType,
    FriendRequestNotification, FriendAcceptedNotification, FriendRemovedNotification,
    GroupJoinRequestNotification,
};
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
            msg_type: request.r#type as i16,
            extra: if request.extra.is_empty() {
                None
            } else {
                serde_json::from_slice(&request.extra).ok()
            },
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

    /// 推送好友申请通知
    pub async fn notify_friend_request(
        &self,
        to_user_id: i64,
        request_id: &str,
        from_user_id: i64,
        nickname: &str,
        avatar: Option<&str>,
        message: Option<&str>,
        created_at: i64,
    ) {
        let notification = FriendRequestNotification {
            request_id: request_id.to_string(),
            from_user_id: from_user_id.to_string(),
            nickname: nickname.to_string(),
            avatar: avatar.unwrap_or_default().to_string(),
            message: message.unwrap_or_default().to_string(),
            created_at,
        };
        let frame = WsFrame {
            r#type: WsFrameType::FriendRequest as i32,
            payload: notification.encode_to_vec(),
        };
        self.ws_state.send_to_user(to_user_id, frame.encode_to_vec()).await;
        println!("📨 [dispatcher] friend_request notification sent to user {}", to_user_id);
    }

    /// 推送好友接受通知
    pub async fn notify_friend_accepted(
        &self,
        to_user_id: i64,
        friend_id: i64,
        nickname: &str,
        avatar: Option<&str>,
        created_at: i64,
    ) {
        let notification = FriendAcceptedNotification {
            friend_id: friend_id.to_string(),
            nickname: nickname.to_string(),
            avatar: avatar.unwrap_or_default().to_string(),
            created_at,
        };
        let frame = WsFrame {
            r#type: WsFrameType::FriendAccepted as i32,
            payload: notification.encode_to_vec(),
        };
        self.ws_state.send_to_user(to_user_id, frame.encode_to_vec()).await;
        println!("📨 [dispatcher] friend_accepted notification sent to user {}", to_user_id);
    }

    /// 推送好友删除通知
    pub async fn notify_friend_removed(&self, to_user_id: i64, friend_id: i64) {
        let notification = FriendRemovedNotification {
            friend_id: friend_id.to_string(),
        };
        let frame = WsFrame {
            r#type: WsFrameType::FriendRemoved as i32,
            payload: notification.encode_to_vec(),
        };
        self.ws_state.send_to_user(to_user_id, frame.encode_to_vec()).await;
        println!("📨 [dispatcher] friend_removed notification sent to user {}", to_user_id);
    }

    /// 推送入群申请通知给群主
    pub async fn notify_group_join_request(
        &self,
        to_owner_id: i64,
        request_id: &str,
        from_user_id: i64,
        nickname: &str,
        avatar: Option<&str>,
        message: Option<&str>,
        conversation_id: &str,
        group_name: Option<&str>,
        created_at: i64,
    ) {
        let notification = GroupJoinRequestNotification {
            request_id: request_id.to_string(),
            from_user_id: from_user_id.to_string(),
            nickname: nickname.to_string(),
            avatar: avatar.unwrap_or_default().to_string(),
            message: message.unwrap_or_default().to_string(),
            conversation_id: conversation_id.to_string(),
            group_name: group_name.unwrap_or_default().to_string(),
            created_at,
        };
        let frame = WsFrame {
            r#type: WsFrameType::GroupJoinRequest as i32,
            payload: notification.encode_to_vec(),
        };
        self.ws_state.send_to_user(to_owner_id, frame.encode_to_vec()).await;
        println!("📨 [dispatcher] group_join_request notification sent to owner {}", to_owner_id);
    }
}
