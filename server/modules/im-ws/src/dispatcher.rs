//! 消息分发器

use std::sync::Arc;
use prost::Message as ProstMessage;
use uuid::Uuid;

use im_message::{MessageService, models::NewMessage};

use crate::proto::{
    MessageAck, SendMessageRequest, WsFrame, WsFrameType,
    FriendRequestNotification, FriendAcceptedNotification, FriendRemovedNotification,
    GroupJoinRequestNotification, GroupInfoUpdate,
    UserStatusNotification, OnlineListNotification, ReadReceiptNotification,
};
use crate::state::WsState;

pub struct MessageDispatcher {
    msg_service: Arc<MessageService>,
    ws_state: Arc<WsState>,
    db: sqlx::PgPool,
}

impl MessageDispatcher {
    pub fn new(msg_service: Arc<MessageService>, ws_state: Arc<WsState>, db: sqlx::PgPool) -> Self {
        Self { msg_service, ws_state, db }
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
        conversation_id: &str,
        group_name: &str,
        user_id: i64,
        nickname: &str,
        avatar: Option<&str>,
        message: Option<&str>,
        created_at: i64,
    ) {
        let notification = GroupJoinRequestNotification {
            request_id: request_id.to_string(),
            conversation_id: conversation_id.to_string(),
            group_name: group_name.to_string(),
            user_id: user_id.to_string(),
            nickname: nickname.to_string(),
            avatar: avatar.unwrap_or_default().to_string(),
            message: message.unwrap_or_default().to_string(),
            created_at,
        };
        let frame = WsFrame {
            r#type: WsFrameType::GroupJoinRequest as i32,
            payload: notification.encode_to_vec(),
        };
        self.ws_state.send_to_user(to_owner_id, frame.encode_to_vec()).await;
        println!("📨 [dispatcher] group_join_request notification sent to owner {}", to_owner_id);
    }

    /// 推送群信息变更通知给所有群成员
    pub async fn notify_group_info_update(
        &self,
        member_ids: &[i64],
        conversation_id: &str,
        name: Option<&str>,
        avatar: Option<&str>,
        announcement: Option<&str>,
        status: Option<i32>,
    ) {
        let update = GroupInfoUpdate {
            conversation_id: conversation_id.to_string(),
            name: name.map(|s| s.to_string()),
            avatar: avatar.map(|s| s.to_string()),
            announcement: announcement.map(|s| s.to_string()),
            status,
        };
        let frame = WsFrame {
            r#type: WsFrameType::GroupInfoUpdate as i32,
            payload: update.encode_to_vec(),
        };
        let data = frame.encode_to_vec();
        self.ws_state.send_to_users(member_ids, data).await;
        println!("📨 [dispatcher] group_info_update sent to {:?}", member_ids);
    }

    /// 广播用户上线通知给在线的好友
    pub async fn broadcast_user_online(&self, user_id: i64) {
        let friend_ids = self.get_online_friend_ids(user_id).await;
        if friend_ids.is_empty() { return; }
        let notification = UserStatusNotification { user_id: user_id.to_string() };
        let frame = WsFrame {
            r#type: WsFrameType::UserOnline as i32,
            payload: notification.encode_to_vec(),
        };
        self.ws_state.send_to_users(&friend_ids, frame.encode_to_vec()).await;
        println!("📡 [dispatcher] user {} online, notified {} friends", user_id, friend_ids.len());
    }

    /// 广播用户下线通知给在线的好友
    pub async fn broadcast_user_offline(&self, user_id: i64) {
        let friend_ids = self.get_online_friend_ids(user_id).await;
        if friend_ids.is_empty() { return; }
        let notification = UserStatusNotification { user_id: user_id.to_string() };
        let frame = WsFrame {
            r#type: WsFrameType::UserOffline as i32,
            payload: notification.encode_to_vec(),
        };
        self.ws_state.send_to_users(&friend_ids, frame.encode_to_vec()).await;
        println!("📡 [dispatcher] user {} offline, notified {} friends", user_id, friend_ids.len());
    }

    /// 查询用户的好友中哪些在线
    async fn get_online_friend_ids(&self, user_id: i64) -> Vec<i64> {
        let friend_rows: Vec<(i64,)> = sqlx::query_as(
            "SELECT friend_id FROM friend_relations WHERE user_id = $1"
        )
        .bind(user_id)
        .fetch_all(&self.db)
        .await
        .unwrap_or_default();

        let online_users = self.ws_state.get_online_users().await;
        let online_set: std::collections::HashSet<i64> = online_users.into_iter().collect();

        friend_rows.into_iter()
            .map(|(id,)| id)
            .filter(|id| online_set.contains(id))
            .collect()
    }

    /// 推送在线好友列表给指定用户（认证成功后调用）
    pub async fn send_online_list(&self, user_id: i64) {
        let friend_ids = self.get_online_friend_ids(user_id).await;
        let user_ids: Vec<String> = friend_ids.iter().map(|id| id.to_string()).collect();
        let count = user_ids.len();
        let notification = OnlineListNotification { user_ids };
        let frame = WsFrame {
            r#type: WsFrameType::OnlineList as i32,
            payload: notification.encode_to_vec(),
        };
        self.ws_state.send_to_user(user_id, frame.encode_to_vec()).await;
        println!("📡 [dispatcher] sent online list to user {} ({} friends online)", user_id, count);
    }

    /// 广播已读回执通知给会话其他成员
    pub async fn broadcast_read_receipt(
        &self,
        conversation_id: &str,
        user_id: i64,
        read_seq: i64,
        member_ids: &[i64],
    ) {
        let notification = ReadReceiptNotification {
            conversation_id: conversation_id.to_string(),
            user_id: user_id.to_string(),
            read_seq,
        };
        let frame = WsFrame {
            r#type: WsFrameType::ReadReceipt as i32,
            payload: notification.encode_to_vec(),
        };
        let targets: Vec<i64> = member_ids.iter().filter(|&&id| id != user_id).copied().collect();
        self.ws_state.send_to_users(&targets, frame.encode_to_vec()).await;
    }
}
