use axum::{
    Router,
    routing::post,
};
use std::sync::Arc;

use flash_core::state::AppState;
use super::handler::{send_sms, login, github_login, apple_login, send_email_code};

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/auth/sms", post(send_sms))
        .route("/auth/login", post(login))
        .route("/auth/github", post(github_login))
        .route("/auth/apple", post(apple_login))
        .route("/auth/email/code", post(send_email_code))
}
