use argon2::{Argon2, PasswordHash, PasswordVerifier};
use axum::{
    extract::{ConnectInfo, State},
    http::StatusCode,
    Json,
};
use chrono::Utc;
use rand::Rng;
use std::net::SocketAddr;
use std::sync::Arc;

use flash_core::state::AppState;
use flash_core::AppError;
use super::jwt::generate_token;
use super::login_log::{is_first_login, record_login};
use super::model::{
    AppleLoginRequest, DeviceInfo, EmailCodeRequest, EmailCodeResponse,
    LoginRequest, LoginResponse, LoginType,
    OAuthLoginRequest, SmsRequest, SmsResponse,
};
use super::oauth::{OAuthProvider, find_or_create_by_oauth};
use super::oauth::github::GitHubProvider;
use super::oauth::apple::AppleProvider;
use super::email::sender::{self, SmtpConfig};
use super::welcome::send_welcome;

/// POST /auth/sms — 发送验证码，写入 verify_codes 表
pub async fn send_sms(
    State(state): State<Arc<AppState>>,
    Json(req): Json<SmsRequest>,
) -> Result<Json<SmsResponse>, StatusCode> {
    validate_phone(&req.phone)?;

    let code: String = format!("{:06}", rand::rng().random_range(0..1000000));
    let expires_at = Utc::now() + chrono::Duration::minutes(5);

    println!("📱 验证码 [{}] -> {}", req.phone, code);

    sqlx::query(
        "INSERT INTO verify_codes (identifier, channel, scene, code, expires_at, created_at)
         VALUES ($1, 'sms', 'login', $2, $3, NOW())"
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
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(req): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, AppError> {
    // 仅 sms 类型校验手机号
    if matches!(req.login_type, LoginType::Sms) {
        if req.phone.len() != 11 || !req.phone.starts_with('1') {
            return Err(AppError::bad_request("手机号格式不正确"));
        }
    }

    let result = match req.login_type {
        LoginType::Sms => login_with_sms(&state, &req).await
            .map_err(|_| AppError::bad_request("验证码错误或已过期"))?,
        LoginType::Password => login_with_password(&state, &req).await
            .map_err(|_| AppError::bad_request("账号或密码错误"))?,
        LoginType::Email => login_with_email(&state, &req).await
            .map_err(|_| AppError::bad_request("验证码或密码错误"))?,
    };

    // 首次登录发欢迎消息
    let first = is_first_login(&state.db, result.user_id).await.unwrap_or(false);
    if first {
        let _ = send_welcome(&state.db, result.user_id).await;
    }

    // 记录登录日志
    let ip = addr.ip().to_string();
    let _ = record_login(&state.db, result.user_id, Some(&ip), &req.device_info).await;

    Ok(result)
}

/// POST /auth/github — GitHub OAuth 登录
pub async fn github_login(
    State(state): State<Arc<AppState>>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(req): Json<OAuthLoginRequest>,
) -> Result<Json<LoginResponse>, StatusCode> {
    let provider = GitHubProvider::from_env();
    let ip = addr.ip().to_string();

    oauth_login_flow(&provider, &req.code, &req.device_info, Some(&ip), &state.db)
        .await
        .map(Json)
        .map_err(|e| { println!("❌ GitHub login error: {:?}", e); StatusCode::UNAUTHORIZED })
}

/// POST /auth/apple — Apple OAuth 登录
pub async fn apple_login(
    State(state): State<Arc<AppState>>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(req): Json<AppleLoginRequest>,
) -> Result<Json<LoginResponse>, StatusCode> {
    let provider = AppleProvider::from_env();
    let ip = addr.ip().to_string();

    oauth_login_flow(&provider, &req.identity_token, &req.device_info, Some(&ip), &state.db)
        .await
        .map(Json)
        .map_err(|e| { println!("❌ Apple login error: {:?}", e); StatusCode::UNAUTHORIZED })
}

/// POST /auth/email/code — 发送邮箱验证码
pub async fn send_email_code(
    State(state): State<Arc<AppState>>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(req): Json<EmailCodeRequest>,
) -> Result<Json<EmailCodeResponse>, StatusCode> {
    // 校验邮箱格式
    if !req.email.contains('@') || !req.email.contains('.') {
        return Err(StatusCode::BAD_REQUEST);
    }

    let ip = addr.ip().to_string();

    // 频率限制：同一邮箱或同一 IP 60 秒内只能发一次
    let recent: Option<(chrono::DateTime<Utc>,)> = sqlx::query_as(
        "SELECT created_at FROM verify_codes WHERE identifier = $1 OR request_ip = $2 ORDER BY created_at DESC LIMIT 1"
    )
    .bind(&req.email)
    .bind(&ip)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    if let Some((created_at,)) = recent {
        let elapsed = Utc::now() - created_at;
        if elapsed.num_seconds() < 60 {
            let wait = 60 - elapsed.num_seconds();
            println!("⏱️ 邮箱验证码频率限制: {} (等待 {}s)", req.email, wait);
            return Err(StatusCode::TOO_MANY_REQUESTS);
        }
    }

    // 生成验证码
    let code: String = format!("{:06}", rand::rng().random_range(0..1000000));
    let expires_at = Utc::now() + chrono::Duration::minutes(5);

    // 存入数据库
    sqlx::query(
        "INSERT INTO verify_codes (identifier, channel, scene, code, expires_at, request_ip, sender, created_at)
         VALUES ($1, 'email', 'login', $2, $3, $4, $5, NOW())"
    )
    .bind(&req.email)
    .bind(&code)
    .bind(expires_at)
    .bind(&ip)
    .bind(std::env::var("EMAIL_USERNAME").unwrap_or_default())
    .execute(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // debug 模式不发邮件
    if sender::is_debug_mode() {
        println!("📧 验证码 [{}] -> {} (debug)", req.email, code);
        return Ok(Json(EmailCodeResponse {
            code: Some(code),
            message: "验证码已发送(debug)".into(),
        }));
    }

    // 发送邮件
    let config = SmtpConfig::from_env();
    sender::send_code(&config, &req.email, &code)
        .map_err(|e| { println!("❌ 邮件发送失败: {:?}", e); StatusCode::INTERNAL_SERVER_ERROR })?;

    println!("📧 验证码 [{}] -> 已发送", req.email);
    Ok(Json(EmailCodeResponse {
        code: None,
        message: "验证码已发送".into(),
    }))
}

/// OAuth 登录统一流程
async fn oauth_login_flow(
    provider: &dyn OAuthProvider,
    code: &str,
    device_info: &DeviceInfo,
    ip: Option<&str>,
    db: &sqlx::PgPool,
) -> Result<LoginResponse, flash_core::AppError> {
    let token = provider.exchange_token(code).await?;
    let info = provider.get_user_info(&token).await?;
    let (account_id, is_new) = find_or_create_by_oauth(db, &info).await?;

    // 首次登录发欢迎消息
    let first = is_first_login(db, account_id).await.unwrap_or(false);
    if first || is_new {
        let _ = send_welcome(db, account_id).await;
    }

    // 记录登录日志
    let _ = record_login(db, account_id, ip, device_info).await;

    Ok(LoginResponse {
        token: generate_token(account_id),
        user_id: account_id,
        has_password: false,
    })
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
    let row: Option<(i64, String, chrono::DateTime<Utc>,)> = sqlx::query_as(
        "SELECT id, code, expires_at FROM verify_codes WHERE identifier = $1 AND channel = 'sms' AND scene = 'login' AND status = 0 ORDER BY created_at DESC LIMIT 1"
    )
    .bind(&req.phone)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let (code_id, stored_code, expires_at) = row.ok_or(StatusCode::UNAUTHORIZED)?;

    if stored_code != req.credential || Utc::now() > expires_at {
        return Err(StatusCode::UNAUTHORIZED);
    }

    let _ = sqlx::query("UPDATE verify_codes SET status = 1 WHERE id = $1")
        .bind(code_id)
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
    // 根据输入格式判断查找方式
    let row: Option<(i64, Option<String>,)> = if req.phone.contains('@') {
        // 邮箱
        sqlx::query_as(
            "SELECT account_id, credential FROM auth_credentials
             WHERE auth_type = 'email' AND identifier = $1"
        )
        .bind(&req.phone)
        .fetch_optional(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    } else if req.phone.len() == 11 && req.phone.starts_with('1') {
        // 手机号
        sqlx::query_as(
            "SELECT account_id, credential FROM auth_credentials
             WHERE auth_type = 'phone' AND identifier = $1"
        )
        .bind(&req.phone)
        .fetch_optional(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    } else {
        // 闪讯 ID（account_id）
        let uid: i64 = req.phone.parse().map_err(|_| StatusCode::BAD_REQUEST)?;
        sqlx::query_as(
            "SELECT account_id, credential FROM auth_credentials
             WHERE account_id = $1 AND credential IS NOT NULL
             LIMIT 1"
        )
        .bind(uid)
        .fetch_optional(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    };

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

/// 邮箱验证码/密码登录
async fn login_with_email(
    state: &Arc<AppState>,
    req: &LoginRequest,
) -> Result<Json<LoginResponse>, StatusCode> {
    let email = &req.phone; // phone 字段复用传邮箱

    // 先尝试验证码登录
    let row: Option<(i64, String, chrono::DateTime<Utc>,)> = sqlx::query_as(
        "SELECT id, code, expires_at FROM verify_codes WHERE identifier = $1 AND channel = 'email' AND scene = 'login' AND status = 0 ORDER BY created_at DESC LIMIT 1"
    )
    .bind(email)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    if let Some((code_id, stored_code, expires_at)) = row {
        if stored_code == req.credential && Utc::now() <= expires_at {
            // 验证码匹配，标记已使用
            let _ = sqlx::query("UPDATE verify_codes SET status = 1 WHERE id = $1")
                .bind(code_id)
                .execute(&state.db)
                .await;

            let (user_id, has_password) = find_or_create_user_by_email(state, email).await?;
            println!("🔑 用户登录(email_code): {} (ID: {})", email, user_id);
            return Ok(Json(LoginResponse { token: generate_token(user_id), user_id, has_password }));
        }
    }

    // 验证码不匹配，尝试密码登录
    let row: Option<(i64, Option<String>,)> = sqlx::query_as(
        "SELECT account_id, credential FROM auth_credentials
         WHERE auth_type = 'email' AND identifier = $1"
    )
    .bind(email)
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

    println!("🔑 用户登录(email_password): {} (ID: {})", email, account_id);
    Ok(Json(LoginResponse { token: generate_token(account_id), user_id: account_id, has_password: true }))
}

/// 通过邮箱查找或创建用户
async fn find_or_create_user_by_email(
    state: &Arc<AppState>,
    email: &str,
) -> Result<(i64, bool), StatusCode> {
    let existing: Option<(i64, Option<String>,)> = sqlx::query_as(
        "SELECT account_id, credential FROM auth_credentials
         WHERE auth_type = 'email' AND identifier = $1"
    )
    .bind(email)
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

    let nickname = email.split('@').next().unwrap_or("用户").to_string();
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
         VALUES ($1, 'email', $2, true, NOW())"
    )
    .bind(account_id)
    .bind(email)
    .execute(&mut *tx)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    tx.commit().await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    println!("🆕 新用户注册(email): {} (ID: {})", nickname, account_id);
    Ok((account_id, false))
}

// ─── 扫码登录 ───────────────────────────────────────────────

use axum::extract::Query;
use axum::http::HeaderMap;
use std::collections::HashMap;
use flash_core::jwt::extract_user_id;
use super::model::{ScanCreateResponse, ScanStatusResponse, ScanConfirmRequest, ScanCancelRequest};

/// POST /auth/scan/create — 创建扫码会话
pub async fn scan_create(
    State(state): State<Arc<AppState>>,
) -> Result<Json<ScanCreateResponse>, StatusCode> {
    let token = uuid::Uuid::new_v4().to_string();
    let expires_at = Utc::now() + chrono::Duration::minutes(5);

    sqlx::query(
        "INSERT INTO scan_sessions (token, status, expires_at) VALUES ($1, 0, $2)"
    )
    .bind(&token)
    .bind(expires_at)
    .execute(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let qr_content = format!("flashim://scan/{}", token);
    println!("🔲 扫码会话创建: {}", token);

    Ok(Json(ScanCreateResponse { token, qr_content, expires_at }))
}

/// GET /auth/scan/status?token=xxx — 查询扫码状态
pub async fn scan_status(
    State(state): State<Arc<AppState>>,
    Query(params): Query<HashMap<String, String>>,
) -> Result<Json<ScanStatusResponse>, StatusCode> {
    let token = params.get("token").ok_or(StatusCode::BAD_REQUEST)?;

    let row: Option<(i16, Option<i64>, chrono::DateTime<Utc>,)> = sqlx::query_as(
        "SELECT status, user_id, expires_at FROM scan_sessions WHERE token = $1"
    )
    .bind(token)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let (status, user_id, expires_at) = row.ok_or(StatusCode::NOT_FOUND)?;

    // 过期检测
    if Utc::now() > expires_at && status < 2 {
        return Ok(Json(ScanStatusResponse {
            status: "expired".into(),
            token: None,
            user_id: None,
        }));
    }

    match status {
        0 => Ok(Json(ScanStatusResponse { status: "pending".into(), token: None, user_id: None })),
        1 => Ok(Json(ScanStatusResponse { status: "scanned".into(), token: None, user_id: None })),
        2 => {
            // confirmed: 为桌面端签发 JWT
            let uid = user_id.ok_or(StatusCode::INTERNAL_SERVER_ERROR)?;
            let jwt = generate_token(uid);
            Ok(Json(ScanStatusResponse { status: "confirmed".into(), token: Some(jwt), user_id: Some(uid) }))
        }
        3 => Ok(Json(ScanStatusResponse { status: "cancelled".into(), token: None, user_id: None })),
        _ => Ok(Json(ScanStatusResponse { status: "unknown".into(), token: None, user_id: None })),
    }
}

/// POST /auth/scan/confirm — 手机端扫码/确认
pub async fn scan_confirm(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<ScanConfirmRequest>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;

    let row: Option<(i16, Option<i64>, chrono::DateTime<Utc>,)> = sqlx::query_as(
        "SELECT status, user_id, expires_at FROM scan_sessions WHERE token = $1"
    )
    .bind(&req.scan_token)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let (status, existing_user_id, expires_at) = row.ok_or(StatusCode::BAD_REQUEST)?;

    if Utc::now() > expires_at {
        return Err(StatusCode::BAD_REQUEST);
    }

    match req.action.as_str() {
        "scan" => {
            if status != 0 {
                return Err(StatusCode::CONFLICT);
            }
            sqlx::query("UPDATE scan_sessions SET status = 1, user_id = $1 WHERE token = $2")
                .bind(user_id)
                .bind(&req.scan_token)
                .execute(&state.db)
                .await
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
            println!("📱 扫码确认(scan): user_id={}", user_id);
        }
        "confirm" => {
            if status != 1 {
                return Err(StatusCode::CONFLICT);
            }
            if existing_user_id != Some(user_id) {
                return Err(StatusCode::CONFLICT);
            }
            sqlx::query("UPDATE scan_sessions SET status = 2 WHERE token = $1")
                .bind(&req.scan_token)
                .execute(&state.db)
                .await
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
            println!("✅ 扫码确认(confirm): user_id={}", user_id);
        }
        _ => return Err(StatusCode::BAD_REQUEST),
    }

    Ok(Json(serde_json::json!({ "message": "ok" })))
}

/// POST /auth/scan/cancel — 手机端取消
pub async fn scan_cancel(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<ScanCancelRequest>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;

    let row: Option<(i16, Option<i64>,)> = sqlx::query_as(
        "SELECT status, user_id FROM scan_sessions WHERE token = $1"
    )
    .bind(&req.scan_token)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let (status, existing_user_id) = row.ok_or(StatusCode::BAD_REQUEST)?;

    if status != 1 || existing_user_id != Some(user_id) {
        return Err(StatusCode::CONFLICT);
    }

    sqlx::query("UPDATE scan_sessions SET status = 3 WHERE token = $1")
        .bind(&req.scan_token)
        .execute(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    println!("❌ 扫码取消: user_id={}", user_id);
    Ok(Json(serde_json::json!({ "message": "ok" })))
}
