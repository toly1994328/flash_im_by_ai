use axum::{
    Router,
    routing::post,
};
use std::sync::Arc;

use flash_core::state::AppState;
use super::handler::{send_sms, login, set_password};

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/auth/sms", post(send_sms))
        .route("/auth/login", post(login))
        .route("/auth/password", post(set_password))
}
