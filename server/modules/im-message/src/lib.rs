pub mod models;
pub mod repository;
pub mod seq;
pub mod broadcast;
pub mod service;
mod routes;

pub use service::MessageService;
pub use broadcast::{MessageBroadcaster, NoopBroadcaster};

use std::sync::Arc;

pub fn router(service: Arc<MessageService>) -> axum::Router {
    routes::router(service)
}
