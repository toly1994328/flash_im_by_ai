use axum::{
    Router,
    routing::{get, post},
};
use std::sync::Arc;

use flash_core::state::AppState;
use super::handler::{send_sms, login, github_login, apple_login, send_email_code, scan_create, scan_status, scan_confirm, scan_cancel};
use super::account_handler::delete_account;

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/auth/sms", post(send_sms))
        .route("/auth/login", post(login))
        .route("/auth/github", post(github_login))
        .route("/auth/apple", post(apple_login))
        .route("/auth/email/code", post(send_email_code))
        .route("/auth/scan/create", post(scan_create))
        .route("/auth/scan/status", get(scan_status))
        .route("/auth/scan/confirm", post(scan_confirm))
        .route("/auth/scan/cancel", post(scan_cancel))
        .route("/api/account/delete", post(delete_account))
}
