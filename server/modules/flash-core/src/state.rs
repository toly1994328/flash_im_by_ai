use serde::Serialize;
use sqlx::PgPool;
use std::sync::Arc;

/// 应用共享状态
pub struct AppState {
    pub db: PgPool,
}

/// 用户信息（供 API 响应使用）
#[derive(Clone, Serialize)]
pub struct User {
    pub user_id: i64,
    pub phone: String,
    pub nickname: String,
    pub avatar: String,
    pub signature: String,
}

/// 创建应用状态
pub fn create_app_state(db: PgPool) -> Arc<AppState> {
    Arc::new(AppState { db })
}
