use axum::{
    Router,
    routing::{get, post},
};
use std::sync::Arc;

use crate::state::AppState;
use super::handler::{send_sms, login, profile, set_password};

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/auth/sms", post(send_sms))
        .route("/auth/login", post(login))
        .route("/auth/password", post(set_password))
        .route("/user/profile", get(profile))
}
