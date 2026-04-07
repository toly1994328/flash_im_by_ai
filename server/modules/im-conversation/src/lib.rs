//! IM 会话模块

pub mod models;
pub mod repository;
pub mod service;
mod routes;

pub use service::ConversationService;

pub fn router() -> axum::Router<std::sync::Arc<flash_core::state::AppState>> {
    routes::router()
}
