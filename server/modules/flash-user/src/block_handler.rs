use axum::{
    extract::{Path, Query, State},
    http::{HeaderMap, StatusCode},
    Json,
};
use serde::Deserialize;
use std::sync::Arc;

use flash_core::jwt::extract_user_id;
use flash_core::state::AppState;
use flash_core::AppError;
use super::model::MessageResponse;

#[derive(Deserialize)]
pub struct BlockUserRequest {
    pub blocked_id: i64,
}

#[derive(Deserialize)]
pub struct CheckBlockQuery {
    pub user_id: i64,
}

/// POST /api/blocks — 拉黑用户
pub async fn block_user(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<BlockUserRequest>,
) -> Result<(StatusCode, Json<MessageResponse>), AppError> {
    let blocker_id = extract_user_id(&headers)?;

    if blocker_id == req.blocked_id {
        return Err(AppError::bad_request("不能拉黑自己"));
    }

    // 插入拉黑记录（冲突忽略）
    sqlx::query(
        "INSERT INTO user_blocks (blocker_id, blocked_id) VALUES ($1, $2) ON CONFLICT DO NOTHING"
    )
    .bind(blocker_id)
    .bind(req.blocked_id)
    .execute(&state.db)
    .await?;

    // 双向解除好友关系
    sqlx::query(
        "DELETE FROM friend_relations WHERE \
         (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1)"
    )
    .bind(blocker_id)
    .bind(req.blocked_id)
    .execute(&state.db)
    .await?;

    println!("🚫 拉黑: {} → {}", blocker_id, req.blocked_id);

    Ok((StatusCode::CREATED, Json(MessageResponse { message: "已拉黑".into() })))
}

/// DELETE /api/blocks/{blocked_id} — 取消拉黑
pub async fn unblock_user(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Path(blocked_id): Path<i64>,
) -> Result<Json<MessageResponse>, AppError> {
    let blocker_id = extract_user_id(&headers)?;

    sqlx::query(
        "DELETE FROM user_blocks WHERE blocker_id = $1 AND blocked_id = $2"
    )
    .bind(blocker_id)
    .bind(blocked_id)
    .execute(&state.db)
    .await?;

    println!("✅ 取消拉黑: {} → {}", blocker_id, blocked_id);

    Ok(Json(MessageResponse { message: "已取消拉黑".into() }))
}

/// GET /api/blocks — 获取黑名单列表
pub async fn get_block_list(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
) -> Result<Json<serde_json::Value>, AppError> {
    let blocker_id = extract_user_id(&headers)?;

    let rows: Vec<(i64, String, Option<String>, String)> = sqlx::query_as(
        "SELECT b.blocked_id, p.nickname, p.avatar, to_char(b.created_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') \
         FROM user_blocks b \
         JOIN user_profiles p ON p.account_id = b.blocked_id \
         WHERE b.blocker_id = $1 \
         ORDER BY b.created_at DESC"
    )
    .bind(blocker_id)
    .fetch_all(&state.db)
    .await?;

    let data: Vec<serde_json::Value> = rows
        .into_iter()
        .map(|(user_id, nickname, avatar, blocked_at)| {
            serde_json::json!({
                "user_id": user_id.to_string(),
                "nickname": nickname,
                "avatar": avatar,
                "blocked_at": blocked_at,
            })
        })
        .collect();

    Ok(Json(serde_json::json!({ "data": data })))
}

/// GET /api/blocks/check?user_id=X — 检查是否已拉黑
pub async fn check_block(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Query(q): Query<CheckBlockQuery>,
) -> Result<Json<serde_json::Value>, AppError> {
    let blocker_id = extract_user_id(&headers)?;

    let exists: Option<(i32,)> = sqlx::query_as(
        "SELECT 1 FROM user_blocks WHERE blocker_id = $1 AND blocked_id = $2"
    )
    .bind(blocker_id)
    .bind(q.user_id)
    .fetch_optional(&state.db)
    .await?;

    Ok(Json(serde_json::json!({ "is_blocked": exists.is_some() })))
}
