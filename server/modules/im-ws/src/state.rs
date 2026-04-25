//! WebSocket 在线用户状态管理（支持多端连接）

use std::collections::HashMap;
use tokio::sync::{mpsc, RwLock};

pub type WsSender = mpsc::UnboundedSender<Vec<u8>>;

/// 单个连接信息
pub struct ConnectionInfo {
    pub id: String,
    pub sender: WsSender,
}

/// WebSocket 状态管理
///
/// 管理所有在线用户的 WebSocket 连接，支持同一用户多端登录。
pub struct WsState {
    connections: RwLock<HashMap<i64, Vec<ConnectionInfo>>>,
}

impl WsState {
    pub fn new() -> Self {
        Self { connections: RwLock::new(HashMap::new()) }
    }

    /// 添加连接。返回 true 表示该用户首次上线（之前无连接）。
    pub async fn add(&self, user_id: i64, conn_id: String, sender: WsSender) -> bool {
        let mut conns = self.connections.write().await;
        let entry = conns.entry(user_id).or_insert_with(Vec::new);
        let is_first = entry.is_empty();
        entry.push(ConnectionInfo { id: conn_id, sender });
        is_first
    }

    /// 移除连接。返回 true 表示该用户完全下线（无剩余连接）。
    pub async fn remove(&self, user_id: i64, conn_id: &str) -> bool {
        let mut conns = self.connections.write().await;
        let mut is_last = false;
        if let Some(user_conns) = conns.get_mut(&user_id) {
            user_conns.retain(|c| c.id != conn_id);
            if user_conns.is_empty() {
                conns.remove(&user_id);
                is_last = true;
            }
        }
        is_last
    }

    /// 检查用户是否在线
    pub async fn is_online(&self, user_id: i64) -> bool {
        self.connections.read().await.contains_key(&user_id)
    }

    /// 获取所有在线用户 ID
    pub async fn get_online_users(&self) -> Vec<i64> {
        self.connections.read().await.keys().copied().collect()
    }

    /// 发送消息给指定用户（所有端）
    pub async fn send_to_user(&self, user_id: i64, data: Vec<u8>) {
        let conns = self.connections.read().await;
        if let Some(user_conns) = conns.get(&user_id) {
            for conn in user_conns {
                let _ = conn.sender.send(data.clone());
            }
        }
    }

    /// 发送消息给多个用户
    pub async fn send_to_users(&self, user_ids: &[i64], data: Vec<u8>) {
        let conns = self.connections.read().await;
        for uid in user_ids {
            if let Some(user_conns) = conns.get(uid) {
                for conn in user_conns {
                    let _ = conn.sender.send(data.clone());
                }
            }
        }
    }
}
