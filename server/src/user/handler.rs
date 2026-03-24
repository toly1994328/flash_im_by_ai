use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    Json,
};
use std::sync::Arc;

use flash_core::state::{AppState, User};
use flash_core::jwt::verify_token;

/// GET /user/profile — 获取用户信息（需要 Token）
pub async fn profile(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
) -> Result<Json<User>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    find_user_by_id(&state, user_id).await
}

fn extract_user_id(headers: &HeaderMap) -> Result<i64, StatusCode> {
    let token = headers
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or(StatusCode::UNAUTHORIZED)?;
    verify_token(token).map_err(|_| StatusCode::UNAUTHORIZED)
}

async fn find_user_by_id(
    state: &Arc<AppState>,
    user_id: i64,
) -> Result<Json<User>, StatusCode> {
    let row: Option<(i64, String, Option<String>,)> = sqlx::query_as(
        "SELECT p.account_id, p.nickname, p.avatar
         FROM user_profiles p
         JOIN accounts a ON a.id = p.account_id
         WHERE p.account_id = $1 AND a.status = 0"
    )
    .bind(user_id)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let (account_id, nickname, avatar) = row.ok_or(StatusCode::NOT_FOUND)?;

    let phone_row: Option<(String,)> = sqlx::query_as(
        "SELECT identifier FROM auth_credentials
         WHERE account_id = $1 AND auth_type = 'phone'"
    )
    .bind(account_id)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let phone = phone_row.map(|(p,)| p).unwrap_or_default();

    Ok(Json(User {
        user_id: account_id,
        phone,
        nickname,
        avatar: avatar.unwrap_or_default(),
    }))
}
