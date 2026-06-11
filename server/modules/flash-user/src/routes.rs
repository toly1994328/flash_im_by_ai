use axum::{Router, routing::{get, post, delete}};
use std::sync::Arc;

use flash_core::state::AppState;
use super::handler::{profile, update_profile, set_password, change_password, search_users, get_user_public};
use super::report_handler::create_report;
use super::block_handler::{block_user, unblock_user, get_block_list, check_block};

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/user/profile", get(profile).put(update_profile))
        .route("/user/password", post(set_password).put(change_password))
        .route("/api/users/search", get(search_users))
        .route("/api/users/{id}", get(get_user_public))
        .route("/api/reports", post(create_report))
        .route("/api/blocks", get(get_block_list).post(block_user))
        .route("/api/blocks/check", get(check_block))
        .route("/api/blocks/{blocked_id}", delete(unblock_user))
}
