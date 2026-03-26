use argon2::{Argon2, PasswordHash, PasswordVerifier};
use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use chrono::Utc;
use rand::Rng;
use std::sync::Arc;

use flash_core::state::AppState;
use super::jwt::generate_token;
use super::model::{
    LoginRequest, LoginResponse, LoginType, SmsRequest, SmsResponse,
};

/// POST /auth/sms — 发送验证码，写入 sms_codes 表
pub async fn send_sms(
    State(state): State<Arc<AppState>>,
    Json(req): Json<SmsRequest>,
) -> Result<Json<SmsResponse>, StatusCode> {
    validate_phone(&req.phone)?;

    let code: String = format!("{:06}", rand::rng().random_range(0..1000000));
    let expires_at = Utc::now() + chrono::Duration::minutes(5);

    println!("📱 验证码 [{}] -> {}", req.phone, code);

    sqlx::query(
        "INSERT INTO sms_codes (phone, code, expires_at, created_at)
         VALUES ($1, $2, $3, NOW())
         ON CONFLICT (phone) DO UPDATE SET code = $2, expires_at = $3, created_at = NOW()"
    )
    .bind(&req.phone)
    .bind(&code)
    .bind(expires_at)
    .execute(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(SmsResponse { code, message: "验证码已发送".into() }))
}

/// POST /auth/login — 统一登录接口
pub async fn login(
    State(state): State<Arc<AppState>>,
    Json(req): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, StatusCode> {
    validate_phone(&req.phone)?;

    match req.login_type {
        LoginType::Sms => login_with_sms(&state, &req).await,
        LoginType::Password => login_with_password(&state, &req).await,
    }
}

// ─── 内部函数 ───

fn validate_phone(phone: &str) -> Result<(), StatusCode> {
    if phone.len() == 11 && phone.starts_with('1') {
        Ok(())
    } else {
        Err(StatusCode::BAD_REQUEST)
    }
}

/// 短信验证码登录（登录即注册）
async fn login_with_sms(
    state: &Arc<AppState>,
    req: &LoginRequest,
) -> Result<Json<LoginResponse>, StatusCode> {
    let row: Option<(String, chrono::DateTime<Utc>,)> = sqlx::query_as(
        "SELECT code, expires_at FROM sms_codes WHERE phone = $1"
    )
    .bind(&req.phone)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let (stored_code, expires_at) = row.ok_or(StatusCode::UNAUTHORIZED)?;

    if stored_code != req.credential || Utc::now() > expires_at {
        return Err(StatusCode::UNAUTHORIZED);
    }

    let _ = sqlx::query("DELETE FROM sms_codes WHERE phone = $1")
        .bind(&req.phone)
        .execute(&state.db)
        .await;

    let (user_id, has_password) = find_or_create_user(state, &req.phone).await?;

    println!("🔑 用户登录(sms): {} (ID: {})", req.phone, user_id);
    Ok(Json(LoginResponse { token: generate_token(user_id), user_id, has_password }))
}

/// 密码登录
async fn login_with_password(
    state: &Arc<AppState>,
    req: &LoginRequest,
) -> Result<Json<LoginResponse>, StatusCode> {
    let row: Option<(i64, Option<String>,)> = sqlx::query_as(
        "SELECT account_id, credential FROM auth_credentials
         WHERE auth_type = 'phone' AND identifier = $1"
    )
    .bind(&req.phone)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let (account_id, credential) = row.ok_or(StatusCode::UNAUTHORIZED)?;
    let password_hash = credential.ok_or(StatusCode::UNAUTHORIZED)?;

    let parsed_hash = PasswordHash::new(&password_hash)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    Argon2::default()
        .verify_password(req.credential.as_bytes(), &parsed_hash)
        .map_err(|_| StatusCode::UNAUTHORIZED)?;

    println!("🔑 用户登录(password): {} (ID: {})", req.phone, account_id);
    Ok(Json(LoginResponse { token: generate_token(account_id), user_id: account_id, has_password: true }))
}

/// 查找用户，不存在则自动注册（事务）
async fn find_or_create_user(
    state: &Arc<AppState>,
    phone: &str,
) -> Result<(i64, bool), StatusCode> {
    let existing: Option<(i64, Option<String>,)> = sqlx::query_as(
        "SELECT account_id, credential FROM auth_credentials
         WHERE auth_type = 'phone' AND identifier = $1"
    )
    .bind(phone)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    if let Some((account_id, credential)) = existing {
        return Ok((account_id, credential.is_some()));
    }

    let mut tx = state.db.begin().await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let (account_id,): (i64,) = sqlx::query_as(
        "INSERT INTO accounts (status, created_at, updated_at)
         VALUES (0, NOW(), NOW()) RETURNING id"
    )
    .fetch_one(&mut *tx)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let nickname = format!("用户{}", &phone[phone.len() - 4..]);
    let avatar = format!("identicon:{}", account_id);

    sqlx::query(
        "INSERT INTO user_profiles (account_id, nickname, avatar, updated_at)
         VALUES ($1, $2, $3, NOW())"
    )
    .bind(account_id)
    .bind(&nickname)
    .bind(&avatar)
    .execute(&mut *tx)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    sqlx::query(
        "INSERT INTO auth_credentials (account_id, auth_type, identifier, verified, created_at)
         VALUES ($1, 'phone', $2, true, NOW())"
    )
    .bind(account_id)
    .bind(phone)
    .execute(&mut *tx)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    tx.commit().await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    println!("🆕 新用户注册: {} (ID: {})", nickname, account_id);
    Ok((account_id, false))
}
