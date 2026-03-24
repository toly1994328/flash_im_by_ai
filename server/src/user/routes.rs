use axum::{Router, routing::get};
use std::sync::Arc;

use flash_core::state::AppState;
use super::handler::profile;

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/user/profile", get(profile))
}
