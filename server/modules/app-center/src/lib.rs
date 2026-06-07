mod models;
mod routes;

use axum::Router;
use axum::routing::{get, post, put, delete};
use sqlx::PgPool;

pub fn router(db: PgPool) -> Router {
    Router::new()
        .route("/api/app/list", get(routes::list_apps))
        .route("/api/app", post(routes::create_app))
        .route("/api/app/versions", get(routes::list_versions))
        .route("/api/app/version", get(routes::get_version))
        .route("/api/app/version", post(routes::create_version))
        .route("/api/app/version", put(routes::update_version))
        .route("/api/app/version", delete(routes::delete_version))
        .route("/api/app/version/publish", post(routes::publish_version))
        .route("/api/app/version/unpublish", post(routes::unpublish_version))
        .with_state(db)
}
