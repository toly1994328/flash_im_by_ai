use argon2::{Argon2, PasswordHash, PasswordVerifier};
use axum::{
    extract::State,
    http::HeaderMap,
    Json,
};
use serde::Deserialize;
use std::sync::Arc;

use flash_core::jwt::extract_user_id;
use flash_core::state::AppState;
use flash_core::AppError;

#[derive(Deserialize)]
pub struct DeleteAccountRequest {
    pub password: String,
}

/// POST /api/account/delete — 注销账号
pub async fn delete_account(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<DeleteAccountRequest>,
) -> Result<Json<serde_json::Value>, AppError> {
    let user_id = extract_user_id(&headers)?;

    // 1. 获取密码哈希
    let row: Option<(Option<String>,)> = sqlx::query_as(
        "SELECT credential FROM auth_credentials WHERE account_id = $1 AND auth_type = 'phone'"
    )
    .bind(user_id)
    .fetch_optional(&state.db)
    .await?;

    let password_hash = match row {
        Some((Some(hash),)) => hash,
        Some((None,)) | None => {
            return Err(AppError::bad_request("请先设置密码"));
        }
    };

    // 2. 验证密码
    let parsed_hash = PasswordHash::new(&password_hash)
        .map_err(|e| AppError::internal(e, "delete_account/parse_hash"))?;
    Argon2::default()
        .verify_password(req.password.as_bytes(), &parsed_hash)
        .map_err(|_| AppError::status(axum::http::StatusCode::UNAUTHORIZED))?;

    // 3. 删除用户相关数据
    // 好友关系
    sqlx::query("DELETE FROM friend_relations WHERE user_id = $1 OR friend_id = $1")
        .bind(user_id).execute(&state.db).await?;

    // 好友申请
    sqlx::query("DELETE FROM friend_requests WHERE from_user_id = $1 OR to_user_id = $1")
        .bind(user_id).execute(&state.db).await?;

    // 拉黑记录
    sqlx::query("DELETE FROM user_blocks WHERE blocker_id = $1 OR blocked_id = $1")
        .bind(user_id).execute(&state.db).await?;

    // 举报记录（作为举报人的）
    sqlx::query("DELETE FROM reports WHERE reporter_id = $1")
        .bind(user_id).execute(&state.db).await?;

    // 会话成员
    sqlx::query("DELETE FROM conversation_members WHERE user_id = $1")
        .bind(user_id).execute(&state.db).await?;

    // 用户资料
    sqlx::query("DELETE FROM user_profiles WHERE account_id = $1")
        .bind(user_id).execute(&state.db).await?;

    // 认证凭据
    sqlx::query("DELETE FROM auth_credentials WHERE account_id = $1")
        .bind(user_id).execute(&state.db).await?;

    // 标记账号为已注销
    sqlx::query("UPDATE accounts SET status = 2 WHERE id = $1")
        .bind(user_id).execute(&state.db).await?;

    println!("💀 账号注销: user_id={}", user_id);

    Ok(Json(serde_json::json!({ "message": "注销成功" })))
}
