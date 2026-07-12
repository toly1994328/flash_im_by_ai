//! IM 会话模块

pub mod models;
pub mod repository;
pub mod service;
mod routes;

pub use service::{ConversationService, ConvBroadcaster};

use std::sync::{Arc, OnceLock};

static BROADCASTER: OnceLock<Arc<dyn ConvBroadcaster>> = OnceLock::new();

pub fn get_broadcaster() -> Arc<dyn ConvBroadcaster> {
    BROADCASTER.get().expect("broadcaster not initialized").clone()
}

pub fn router(broadcaster: Arc<dyn ConvBroadcaster>) -> axum::Router<std::sync::Arc<flash_core::state::AppState>> {
    let _ = BROADCASTER.set(broadcaster);
    routes::router()
}
