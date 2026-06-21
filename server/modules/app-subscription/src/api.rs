use std::sync::Arc;

use axum::{
    extract::State,
    http::HeaderMap,
    routing::{get, post},
    Json, Router,
};
use serde::Deserialize;

use flash_core::jwt::extract_user_id;
use flash_core::AppError;

use crate::service::{RedeemResult, SubscriptionService, SubscriptionStatus};

#[derive(Deserialize)]
struct RedeemRequest {
    code: String,
}

/// 构建订阅路由
pub fn router(service: Arc<SubscriptionService>) -> Router {
    Router::new()
        .route("/api/subscriptions/redeem", post(redeem_handler))
        .route("/api/subscriptions/status", get(status_handler))
        .with_state(service)
}

/// POST /api/subscriptions/redeem
async fn redeem_handler(
    State(svc): State<Arc<SubscriptionService>>,
    headers: HeaderMap,
    Json(body): Json<RedeemRequest>,
) -> Result<Json<RedeemResult>, AppError> {
    let user_id = extract_user_id(&headers)?;
    let result = svc.redeem(user_id, &body.code).await?;
    Ok(Json(result))
}

/// GET /api/subscriptions/status
async fn status_handler(
    State(svc): State<Arc<SubscriptionService>>,
    headers: HeaderMap,
) -> Result<Json<SubscriptionStatus>, AppError> {
    let user_id = extract_user_id(&headers)?;
    let status = svc.get_status(user_id).await?;
    Ok(Json(status))
}
