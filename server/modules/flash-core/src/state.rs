use serde::Serialize;
use sqlx::PgPool;
use std::sync::Arc;
use tokio::sync::broadcast;

/// 应用共享状态
pub struct AppState {
    pub db: PgPool,                             // 数据库连接池
    pub chat_tx: broadcast::Sender<String>,     // 聊天室广播
}

/// 用户信息（供 WebSocket 等模块使用）
#[derive(Clone, Serialize)]
pub struct User {
    pub user_id: i64,
    pub phone: String,
    pub nickname: String,
    pub avatar: String,
}

/// 创建应用状态
pub fn create_app_state(db: PgPool) -> Arc<AppState> {
    let (chat_tx, _) = broadcast::channel::<String>(256);
    Arc::new(AppState { db, chat_tx })
}
