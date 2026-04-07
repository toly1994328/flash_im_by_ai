use axum::{Router, routing::{get, post}};
use std::sync::Arc;

use flash_core::state::AppState;
use super::handler::{profile, update_profile, set_password, change_password, search_users};

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/user/profile", get(profile).put(update_profile))
        .route("/user/password", post(set_password).put(change_password))
        .route("/api/users/search", get(search_users))
}
