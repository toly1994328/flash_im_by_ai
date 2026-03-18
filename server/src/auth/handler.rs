use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    Json,
};
use rand::Rng;
use std::sync::Arc;

use crate::state::{AppState, User};
use super::jwt::{generate_token, verify_token};
use super::model::{LoginRequest, LoginResponse, SmsRequest, SmsResponse};

/// POST /auth/sms — 发送验证码（模拟）
pub async fn send_sms(
    State(state): State<Arc<AppState>>,
    Json(req): Json<SmsRequest>,
) -> Result<Json<SmsResponse>, StatusCode> {
    if req.phone.len() != 11 || !req.phone.starts_with('1') {
        return Err(StatusCode::BAD_REQUEST);
    }
    let code: String = format!("{:06}", rand::rng().random_range(0..1000000));
    println!("📱 验证码 [{}] -> {}", req.phone, code);
    state.sms_codes.lock().await.insert(req.phone, code.clone());
    Ok(Json(SmsResponse { code, message: "验证码已发送".into() }))
}

/// POST /auth/login — 验证码登录（登录即注册）
pub async fn login(
    State(state): State<Arc<AppState>>,
    Json(req): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, StatusCode> {
    if req.phone.len() != 11 || !req.phone.starts_with('1') {
        return Err(StatusCode::BAD_REQUEST);
    }
    let codes = state.sms_codes.lock().await;
    match codes.get(&req.phone) {
        Some(c) if c == &req.code => {}
        _ => return Err(StatusCode::UNAUTHORIZED),
    }
    drop(codes);

    let mut users = state.users.lock().await;
    let user = if let Some(u) = users.get(&req.phone) {
        u.clone()
    } else {
        let mut next_id = state.next_id.lock().await;
        *next_id += 1;
        let user = User {
            user_id: *next_id,
            phone: req.phone.clone(),
            nickname: req.phone.clone(),
            avatar: format!("https://picsum.photos/seed/{}/100/100", *next_id),
        };
        users.insert(req.phone.clone(), user.clone());
        println!("🆕 新用户注册: {} (ID: {})", req.phone, user.user_id);
        user
    };

    state.sms_codes.lock().await.remove(&req.phone);

    let token = generate_token(user.user_id);
    println!("🔑 用户登录: {} (ID: {})", req.phone, user.user_id);
    Ok(Json(LoginResponse { token, user_id: user.user_id }))
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
