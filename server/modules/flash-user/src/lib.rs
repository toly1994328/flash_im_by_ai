mod handler;
mod model;
mod report_handler;
mod block_handler;
mod routes;

use axum::Router;
use flash_core::state::AppState;
use std::sync::Arc;

pub fn router() -> Router<Arc<AppState>> {
    routes::router()
}
