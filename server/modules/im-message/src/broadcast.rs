use async_trait::async_trait;
use uuid::Uuid;

use crate::models::Message;

/// 消息广播器 trait（im-ws 实现）
#[async_trait]
pub trait MessageBroadcaster: Send + Sync {
    /// 广播消息给会话成员
    async fn broadcast_message(
        &self,
        message: &Message,
        member_ids: &[i64],
        exclude_sender: bool,
    );

    /// 广播会话更新给会话成员
    async fn broadcast_conversation_update(
        &self,
        conversation_id: Uuid,
        preview: &str,
        member_ids: &[i64],
        sender_id: i64,
        msg_extra: &str,
    );

    /// 广播消息撤回给会话成员
    async fn broadcast_recalled(
        &self,
        message_id: Uuid,
        conversation_id: Uuid,
        sender_id: i64,
        sender_name: &str,
        member_ids: &[i64],
    );

    /// 广播置顶变更给会话成员
    async fn broadcast_pin_changed(
        &self,
        conversation_id: Uuid,
        message_id: Uuid,
        action: &str,
        pinned_by: i64,
        member_ids: &[i64],
    );
}

/// 空广播器（测试用）
pub struct NoopBroadcaster;

#[async_trait]
impl MessageBroadcaster for NoopBroadcaster {
    async fn broadcast_message(&self, _: &Message, _: &[i64], _: bool) {}
    async fn broadcast_conversation_update(&self, _: Uuid, _: &str, _: &[i64], _: i64, _: &str) {}
    async fn broadcast_recalled(&self, _: Uuid, _: Uuid, _: i64, _: &str, _: &[i64]) {}
    async fn broadcast_pin_changed(&self, _: Uuid, _: Uuid, _: &str, _: i64, _: &[i64]) {}
}
