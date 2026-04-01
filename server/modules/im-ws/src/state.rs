//! WebSocket 在线用户状态管理

use std::collections::HashMap;
use tokio::sync::{mpsc, RwLock};

pub type WsSender = mpsc::UnboundedSender<Vec<u8>>;

pub struct WsState {
    connections: RwLock<HashMap<i64, WsSender>>,
}

impl WsState {
    pub fn new() -> Self {
        Self { connections: RwLock::new(HashMap::new()) }
    }

    pub async fn add(&self, user_id: i64, sender: WsSender) {
        self.connections.write().await.insert(user_id, sender);
    }

    pub async fn remove(&self, user_id: i64) {
        self.connections.write().await.remove(&user_id);
    }

    pub async fn send_to_user(&self, user_id: i64, data: Vec<u8>) {
        let conns = self.connections.read().await;
        if let Some(tx) = conns.get(&user_id) {
            let _ = tx.send(data);
        }
    }

    pub async fn send_to_users(&self, user_ids: &[i64], data: Vec<u8>) {
        let conns = self.connections.read().await;
        for uid in user_ids {
            if let Some(tx) = conns.get(uid) {
                let _ = tx.send(data.clone());
            }
        }
    }
}
