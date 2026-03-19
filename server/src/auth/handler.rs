use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    Json,
};
use rand::Rng;
use std::sync::Arc;

use crate::state::{AppState, User};
use super::jwt::{generate_token, verify_token};
use super::model::{LoginRequest, LoginResponse, LoginType, SmsRequest, SmsResponse};

/// 内置测试账号（手机号, 密码, 昵称）
const BUILTIN_ACCOUNTS: &[(&str, &str, &str)] = &[
    ("13800000001", "123456", "张三"),
    ("13800000002", "123456", "李四"),
    ("13800000003", "abcdef", "王五"),
];

/// POST /auth/sms — 发送验证码（模拟）
pub async fn send_sms(
    State(state): State<Arc<AppState>>,
    Json(req): Json<SmsRequest>,
) -> Result<Json<SmsResponse>, StatusCode> {
    validate_phone(&req.phone)?;
    let code: String = format!("{:06}", rand::rng().random_range(0..1000000));
    println!("📱 验证码 [{}] -> {}", req.phone, code);
    state.sms_codes.lock().await.insert(req.phone, code.clone());
    Ok(Json(SmsResponse { code, message: "验证码已发送".into() }))
}

/// POST /auth/login — 统一登录接口，通过 type 区分方式
pub async fn login(
    State(state): State<Arc<AppState>>,
    Json(req): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, StatusCode> {
    validate_phone(&req.phone)?;

    // 验证凭证，返回昵称
    let nickname = verify_credential(&state, &req).await?;

    let user = find_or_create_user(&state, &req.phone, &nickname).await;
    println!("🔑 用户登录({:?}): {} (ID: {})", req.login_type, user.nickname, user.user_id);
    Ok(Json(LoginResponse { token: generate_token(user.user_id), user_id: user.user_id }))
}

/// GET /user/profile — 获取用户信息（需要 Token）
pub async fn profile(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
) -> Result<Json<User>, StatusCode> {
    let token = headers
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let user_id = verify_token(token).map_err(|_| StatusCode::UNAUTHORIZED)?;

    let users = state.users.lock().await;
    users
        .values()
        .find(|u| u.user_id == user_id)
        .cloned()
        .ok_or(StatusCode::NOT_FOUND)
        .map(Json)
}

// ─── 内部工具函数 ───

fn validate_phone(phone: &str) -> Result<(), StatusCode> {
    if phone.len() == 11 && phone.starts_with('1') {
        Ok(())
    } else {
        Err(StatusCode::BAD_REQUEST)
    }
}

/// 根据登录类型验证凭证，返回昵称
async fn verify_credential(
    state: &Arc<AppState>,
    req: &LoginRequest,
) -> Result<String, StatusCode> {
    match req.login_type {
        LoginType::Sms => {
            let codes = state.sms_codes.lock().await;
            match codes.get(&req.phone) {
                Some(c) if c == &req.credential => {}
                _ => return Err(StatusCode::UNAUTHORIZED),
            }
            drop(codes);
            state.sms_codes.lock().await.remove(&req.phone);
            Ok(req.phone.clone())
        }
        LoginType::Password => {
            let account = BUILTIN_ACCOUNTS
                .iter()
                .find(|(phone, pwd, _)| *phone == req.phone && *pwd == req.credential)
                .ok_or(StatusCode::UNAUTHORIZED)?;
            Ok(account.2.to_string())
        }
    }
}

async fn find_or_create_user(state: &Arc<AppState>, phone: &str, nickname: &str) -> User {
    let mut users = state.users.lock().await;
    if let Some(u) = users.get(phone) {
        return u.clone();
    }
    let mut next_id = state.next_id.lock().await;
    *next_id += 1;
    let user = User {
        user_id: *next_id,
        phone: phone.to_string(),
        nickname: nickname.to_string(),
        avatar: format!("https://picsum.photos/seed/{}/100/100", *next_id),
    };
    users.insert(phone.to_string(), user.clone());
    println!("🆕 新用户注册: {} (ID: {})", user.nickname, user.user_id);
    user
}
