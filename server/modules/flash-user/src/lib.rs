mod handler;
mod model;
mod routes;

use axum::Router;
use flash_core::state::AppState;
use std::sync::Arc;

pub fn router() -> Router<Arc<AppState>> {
    routes::router()
}
