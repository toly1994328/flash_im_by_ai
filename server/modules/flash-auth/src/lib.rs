mod handler;
mod jwt;
mod login_log;
mod model;
mod oauth;
mod routes;
mod welcome;

use axum::Router;
use flash_core::state::AppState;
use std::sync::Arc;

/// flash-auth 的公开 API — 只有这一个函数
pub fn router() -> Router<Arc<AppState>> {
    routes::router()
}
