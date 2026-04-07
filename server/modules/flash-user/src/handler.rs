use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use argon2::password_hash::SaltString;
use axum::{
    extract::{Query, State},
    http::{HeaderMap, StatusCode},
    Json,
};
use serde::Deserialize;
use std::sync::Arc;

use flash_core::jwt::extract_user_id;
use flash_core::state::{AppState, User};
use super::model::{
    ChangePasswordRequest, MessageResponse, SetPasswordRequest, UpdateProfileRequest,
};

/// GET /user/profile
pub async fn profile(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
) -> Result<Json<User>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    find_user_by_id(&state, user_id).await
}

/// PUT /user/profile
pub async fn update_profile(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<UpdateProfileRequest>,
) -> Result<Json<User>, StatusCode> {
    let user_id = extract_user_id(&headers)?;

    // 校验字段长度
    if let Some(ref nickname) = req.nickname {
        if nickname.is_empty() || nickname.len() > 50 {
            return Err(StatusCode::BAD_REQUEST);
        }
    }
    if let Some(ref signature) = req.signature {
        if signature.len() > 100 {
            return Err(StatusCode::BAD_REQUEST);
        }
    }

    // 动态构建 UPDATE SQL
    let mut sets: Vec<String> = vec![];
    let mut args: Vec<String> = vec![];
    let mut idx = 2u32; // $1 = account_id

    if let Some(ref nickname) = req.nickname {
        sets.push(format!("nickname = ${idx}"));
        args.push(nickname.clone());
        idx += 1;
    }
    if let Some(ref avatar) = req.avatar {
        sets.push(format!("avatar = ${idx}"));
        args.push(avatar.clone());
        idx += 1;
    }
    if let Some(ref signature) = req.signature {
        sets.push(format!("signature = ${idx}"));
        args.push(signature.clone());
    }

    if sets.is_empty() {
        return find_user_by_id(&state, user_id).await;
    }

    let sql = format!(
        "UPDATE user_profiles SET {}, updated_at = NOW() WHERE account_id = $1",
        sets.join(", ")
    );

    let mut query = sqlx::query(&sql).bind(user_id);
    for arg in &args {
        query = query.bind(arg);
    }

    query.execute(&state.db).await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    find_user_by_id(&state, user_id).await
}

/// POST /user/password — 首次设置密码
pub async fn set_password(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<SetPasswordRequest>,
) -> Result<Json<MessageResponse>, StatusCode> {
    let user_id = extract_user_id(&headers)?;

    if req.new_password.len() < 6 {
        return Err(StatusCode::BAD_REQUEST);
    }

    // 检查是否已设置过密码
    let row: Option<(Option<String>,)> = sqlx::query_as(
        "SELECT credential FROM auth_credentials WHERE account_id = $1 AND auth_type = 'phone'"
    )
    .bind(user_id)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    match row {
        Some((Some(_),)) => return Err(StatusCode::CONFLICT), // 409: 已有密码
        Some((None,)) => {}
        None => return Err(StatusCode::NOT_FOUND),
    }

    let salt = SaltString::generate(&mut argon2::password_hash::rand_core::OsRng);
    let password_hash = Argon2::default()
        .hash_password(req.new_password.as_bytes(), &salt)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .to_string();

    sqlx::query(
        "UPDATE auth_credentials SET credential = $1 WHERE account_id = $2 AND auth_type = 'phone'"
    )
    .bind(&password_hash)
    .bind(user_id)
    .execute(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    println!("🔒 密码设置: user_id={}", user_id);
    Ok(Json(MessageResponse { message: "密码设置成功".into() }))
}

/// PUT /user/password — 修改密码（需验证旧密码）
pub async fn change_password(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<ChangePasswordRequest>,
) -> Result<Json<MessageResponse>, StatusCode> {
    let user_id = extract_user_id(&headers)?;

    if req.new_password.len() < 6 {
        return Err(StatusCode::BAD_REQUEST);
    }

    // 查询现有密码
    let row: Option<(Option<String>,)> = sqlx::query_as(
        "SELECT credential FROM auth_credentials WHERE account_id = $1 AND auth_type = 'phone'"
    )
    .bind(user_id)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let password_hash = match row {
        Some((Some(hash),)) => hash,
        Some((None,)) => return Err(StatusCode::NOT_FOUND), // 404: 未设置过密码
        None => return Err(StatusCode::NOT_FOUND),
    };

    // 验证旧密码
    let parsed_hash = PasswordHash::new(&password_hash)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    Argon2::default()
        .verify_password(req.old_password.as_bytes(), &parsed_hash)
        .map_err(|_| StatusCode::UNAUTHORIZED)?;

    // 哈希新密码
    let salt = SaltString::generate(&mut argon2::password_hash::rand_core::OsRng);
    let new_hash = Argon2::default()
        .hash_password(req.new_password.as_bytes(), &salt)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .to_string();

    sqlx::query(
        "UPDATE auth_credentials SET credential = $1 WHERE account_id = $2 AND auth_type = 'phone'"
    )
    .bind(&new_hash)
    .bind(user_id)
    .execute(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    println!("🔒 密码修改: user_id={}", user_id);
    Ok(Json(MessageResponse { message: "密码修改成功".into() }))
}

// ─── 内部辅助函数 ───

async fn find_user_by_id(
    state: &Arc<AppState>,
    user_id: i64,
) -> Result<Json<User>, StatusCode> {
    let row: Option<(i64, String, Option<String>, Option<String>)> = sqlx::query_as(
        "SELECT p.account_id, p.nickname, p.avatar, p.signature
         FROM user_profiles p
         JOIN accounts a ON a.id = p.account_id
         WHERE p.account_id = $1 AND a.status = 0"
    )
    .bind(user_id)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let (account_id, nickname, avatar, signature) = row.ok_or(StatusCode::NOT_FOUND)?;

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
        signature: signature.unwrap_or_default(),
    }))
}

// ─── 用户搜索 ───

#[derive(Deserialize)]
pub struct SearchQuery {
    pub keyword: String,
    #[serde(default = "default_search_limit")]
    pub limit: i32,
}

fn default_search_limit() -> i32 { 20 }

/// GET /api/users/search
pub async fn search_users(
    State(state): State<Arc<AppState>>,
    Query(query): Query<SearchQuery>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let keyword = query.keyword.replace('%', "\\%").replace('_', "\\_");
    let pattern = format!("%{}%", keyword);
    let limit = query.limit.min(50).max(1);

    let rows: Vec<(i64, String, Option<String>)> = sqlx::query_as(
        "SELECT p.account_id, p.nickname, p.avatar \
         FROM user_profiles p \
         JOIN accounts a ON a.id = p.account_id \
         WHERE a.status = 0 AND p.nickname ILIKE $1 \
         ORDER BY p.nickname \
         LIMIT $2",
    )
    .bind(&pattern)
    .bind(limit)
    .fetch_all(&state.db)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let data: Vec<serde_json::Value> = rows
        .into_iter()
        .map(|(id, nickname, avatar)| {
            serde_json::json!({
                "id": id.to_string(),
                "nickname": nickname,
                "avatar": avatar,
            })
        })
        .collect();

    Ok(Json(serde_json::json!({ "data": data })))
}
