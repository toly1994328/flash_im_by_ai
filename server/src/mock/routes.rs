use axum::{Router, routing::get};
use std::sync::Arc;

use flash_core::state::AppState;
use super::handler::{conversation, version};

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/v", get(version))
        .route("/conversation", get(conversation))
}
