use axum::{
    Router,
    routing::{get, post},
};
use std::sync::Arc;

use crate::state::AppState;
use super::handler::{send_sms, login, profile};

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/auth/sms", post(send_sms))
        .route("/auth/login", post(login))
        .route("/user/profile", get(profile))
}
