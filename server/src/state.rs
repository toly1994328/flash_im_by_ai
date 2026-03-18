use serde::Serialize;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::{broadcast, Mutex};

/// 应用共享状态
pub struct AppState {
    pub users: Mutex<HashMap<String, User>>,       // phone -> User
    pub sms_codes: Mutex<HashMap<String, String>>, // phone -> code
    pub next_id: Mutex<i64>,
    pub chat_tx: broadcast::Sender<String>,        // 聊天室广播
}

/// 用户信息
#[derive(Clone, Serialize)]
pub struct User {
    pub user_id: i64,
    pub phone: String,
    pub nickname: String,
    pub avatar: String,
}

/// 创建初始应用状态
pub fn create_app_state() -> Arc<AppState> {
    let (chat_tx, _) = broadcast::channel::<String>(256);
    Arc::new(AppState {
        users: Mutex::new(HashMap::new()),
        sms_codes: Mutex::new(HashMap::new()),
        next_id: Mutex::new(0),
        chat_tx,
    })
}
