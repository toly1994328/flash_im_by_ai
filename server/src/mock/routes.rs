use axum::{Router, routing::get};
use std::sync::Arc;

use crate::state::AppState;
use super::handler::{conversation, version};

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/v", get(version))
        .route("/conversation", get(conversation))
}
