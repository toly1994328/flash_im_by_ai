use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use argon2::password_hash::SaltString;
use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    Json,
};
use chrono::Utc;
use rand::Rng;
use std::sync::Arc;

use crate::state::{AppState, User};
use super::jwt::{generate_token, verify_token};
use super::model::{
    LoginRequest, LoginResponse, LoginType, MessageResponse,
    PasswordRequest, SmsRequest, SmsResponse,
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

    // INSERT or UPDATE（同一手机号覆盖旧验证码）
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

/// GET /user/profile — 获取用户信息（需要 Token）
pub async fn profile(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
) -> Result<Json<User>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    find_user_by_id(&state, user_id).await
}

/// POST /auth/password — 设置密码（需 Token）
pub async fn set_password(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<PasswordRequest>,
) -> Result<Json<MessageResponse>, StatusCode> {
    let user_id = extract_user_id(&headers)?;

    if req.new_password.len() < 6 {
        return Err(StatusCode::BAD_REQUEST);
    }

    let salt = SaltString::generate(&mut argon2::password_hash::rand_core::OsRng);
    let password_hash = Argon2::default()
        .hash_password(req.new_password.as_bytes(), &salt)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .to_string();

    sqlx::query(
        "UPDATE auth_credentials SET credential = $1
         WHERE account_id = $2 AND auth_type = 'phone'"
    )
    .bind(&password_hash)
    .bind(user_id)
    .execute(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    println!("🔒 密码设置: user_id={}", user_id);
    Ok(Json(MessageResponse { message: "密码设置成功".into() }))
}

// ─── 内部函数 ───

fn extract_user_id(headers: &HeaderMap) -> Result<i64, StatusCode> {
    let token = headers
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or(StatusCode::UNAUTHORIZED)?;
    verify_token(token).map_err(|_| StatusCode::UNAUTHORIZED)
}

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
    // 查验证码
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

    // 验证通过，删除验证码
    let _ = sqlx::query("DELETE FROM sms_codes WHERE phone = $1")
        .bind(&req.phone)
        .execute(&state.db)
        .await;

    // 查找或创建用户
    let (user_id, has_password) = find_or_create_user(state, &req.phone).await?;

    println!("🔑 用户登录(sms): {} (ID: {})", req.phone, user_id);
    Ok(Json(LoginResponse { token: generate_token(user_id), user_id, has_password }))
}

/// 密码登录
async fn login_with_password(
    state: &Arc<AppState>,
    req: &LoginRequest,
) -> Result<Json<LoginResponse>, StatusCode> {
    // 查认证凭据
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

    // Argon2 验证密码
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
    // 先查是否已有该手机号
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

    // 不存在，开事务创建
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
    let avatar = format!("https://picsum.photos/seed/{}/100/100", account_id);

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

/// 通过 account_id 查询用户信息
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

    // 查手机号
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
