/// 管理后台 API（仅 user_id 1/2 可用）
use axum::{extract::{Query, State}, http::HeaderMap, routing::get, Json, Router};
use serde::Serialize;
use sqlx::PgPool;

use flash_core::jwt::verify_token;

fn extract_admin(headers: &HeaderMap) -> Result<i64, axum::http::StatusCode> {
    let token = headers.get("authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or(axum::http::StatusCode::UNAUTHORIZED)?;
    let user_id = verify_token(token).map_err(|_| axum::http::StatusCode::UNAUTHORIZED)?;
    if user_id != 1 && user_id != 2 {
        return Err(axum::http::StatusCode::FORBIDDEN);
    }
    Ok(user_id)
}

// ─── Users ───

#[derive(Serialize, sqlx::FromRow)]
struct AdminUser {
    id: i64,
    nickname: Option<String>,
    avatar: Option<String>,
    status: i16,
    created_at: chrono::DateTime<chrono::Utc>,
}

async fn list_users(
    State(db): State<PgPool>,
    headers: HeaderMap,
) -> Result<Json<Vec<AdminUser>>, axum::http::StatusCode> {
    extract_admin(&headers)?;
    let users: Vec<AdminUser> = sqlx::query_as(
        "SELECT a.id, p.nickname, p.avatar, a.status, a.created_at \
         FROM accounts a LEFT JOIN user_profiles p ON a.id = p.account_id \
         ORDER BY a.id"
    )
    .fetch_all(&db)
    .await
    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?;
    Ok(Json(users))
}

// ─── User Conversations ───

#[derive(serde::Deserialize)]
struct UserConvQuery {
    user_id: i64,
}

#[derive(Serialize, sqlx::FromRow)]
struct UserConversation {
    id: String,
    #[sqlx(rename = "type")]
    conv_type: i16,
    name: Option<String>,
    peer_name: Option<String>,
    last_message_preview: Option<String>,
    last_message_at: Option<chrono::DateTime<chrono::Utc>>,
}

async fn list_user_conversations(
    State(db): State<PgPool>,
    headers: HeaderMap,
    Query(params): Query<UserConvQuery>,
) -> Result<Json<Vec<UserConversation>>, axum::http::StatusCode> {
    extract_admin(&headers)?;
    let convs: Vec<UserConversation> = sqlx::query_as(
        "SELECT c.id::text, c.type, c.name, \
                (SELECT COALESCE(p.nickname, '?') FROM conversation_members cm2 \
                 LEFT JOIN user_profiles p ON cm2.user_id = p.account_id \
                 WHERE cm2.conversation_id = c.id AND cm2.user_id != $1 AND cm2.is_deleted = false \
                 LIMIT 1) as peer_name, \
                c.last_message_preview, c.last_message_at \
         FROM conversations c \
         INNER JOIN conversation_members cm ON cm.conversation_id = c.id AND cm.user_id = $1 AND cm.is_deleted = false \
         ORDER BY c.last_message_at DESC NULLS LAST"
    )
    .bind(params.user_id)
    .fetch_all(&db)
    .await
    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?;
    Ok(Json(convs))
}

// ─── Conversations ───

#[derive(Serialize, sqlx::FromRow)]
struct AdminConversation {
    id: String,
    #[sqlx(rename = "type")]
    conv_type: i16,
    name: Option<String>,
    owner_id: Option<i64>,
    member_count: Option<i64>,
    member_names: Option<String>,
    last_message_preview: Option<String>,
    last_message_at: Option<chrono::DateTime<chrono::Utc>>,
    created_at: chrono::DateTime<chrono::Utc>,
}

async fn list_conversations(
    State(db): State<PgPool>,
    headers: HeaderMap,
) -> Result<Json<Vec<AdminConversation>>, axum::http::StatusCode> {
    extract_admin(&headers)?;
    let convs: Vec<AdminConversation> = sqlx::query_as(
        "SELECT c.id::text, c.type, c.name, c.owner_id, \
                (SELECT COUNT(*) FROM conversation_members cm WHERE cm.conversation_id = c.id AND cm.is_deleted = false) as member_count, \
                (SELECT string_agg(COALESCE(p.nickname, '?'), ' · ' ORDER BY cm2.user_id) \
                 FROM conversation_members cm2 \
                 LEFT JOIN user_profiles p ON cm2.user_id = p.account_id \
                 WHERE cm2.conversation_id = c.id AND cm2.is_deleted = false \
                 LIMIT 1) as member_names, \
                c.last_message_preview, c.last_message_at, c.created_at \
         FROM conversations c \
         ORDER BY c.last_message_at DESC NULLS LAST \
         LIMIT 100"
    )
    .fetch_all(&db)
    .await
    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?;
    Ok(Json(convs))
}

// ─── Files/Resources ───

#[derive(Serialize, sqlx::FromRow)]
struct AdminFile {
    id: i64,
    storage_path: String,
    original_name: Option<String>,
    size: i64,
    mime_type: String,
    mime_category: String,
    width: Option<i32>,
    height: Option<i32>,
    duration_ms: Option<i64>,
    thumb_path: Option<String>,
    ref_count: Option<i32>,
    uploader_name: Option<String>,
    created_at: chrono::DateTime<chrono::Utc>,
}

async fn list_files(
    State(db): State<PgPool>,
    headers: HeaderMap,
) -> Result<Json<Vec<AdminFile>>, axum::http::StatusCode> {
    extract_admin(&headers)?;
    let files: Vec<AdminFile> = sqlx::query_as(
        "SELECT f.id, f.storage_path, f.original_name, f.size, f.mime_type, f.mime_category, \
                f.width, f.height, f.duration_ms, f.thumb_path, f.ref_count, \
                p.nickname as uploader_name, f.created_at \
         FROM file_objects f \
         LEFT JOIN user_profiles p ON f.uploader_id = p.account_id \
         ORDER BY f.created_at DESC \
         LIMIT 200"
    )
    .fetch_all(&db)
    .await
    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?;
    Ok(Json(files))
}

// ─── Messages ───

#[derive(Serialize, sqlx::FromRow)]
struct AdminMessage {
    id: String,
    conversation_id: String,
    sender_id: i64,
    sender_name: Option<String>,
    seq: i64,
    #[sqlx(rename = "type")]
    msg_type: i16,
    content: String,
    status: i16,
    created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(serde::Deserialize)]
struct MessageQuery {
    conversation_id: String,
}

async fn list_messages(
    State(db): State<PgPool>,
    headers: HeaderMap,
    Query(params): Query<MessageQuery>,
) -> Result<Json<Vec<AdminMessage>>, axum::http::StatusCode> {
    extract_admin(&headers)?;
    let conv_id: uuid::Uuid = params.conversation_id.parse()
        .map_err(|_| axum::http::StatusCode::BAD_REQUEST)?;
    let msgs: Vec<AdminMessage> = sqlx::query_as(
        "SELECT m.id::text, m.conversation_id::text, m.sender_id, \
                COALESCE(p.nickname, '未知') as sender_name, \
                m.seq, m.type, m.content, m.status, m.created_at \
         FROM messages m \
         LEFT JOIN user_profiles p ON m.sender_id = p.account_id \
         WHERE m.conversation_id = $1 \
         ORDER BY m.seq DESC \
         LIMIT 100"
    )
    .bind(conv_id)
    .fetch_all(&db)
    .await
    .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?;
    Ok(Json(msgs))
}

pub fn router(db: PgPool) -> Router {
    Router::new()
        .route("/api/admin/users", get(list_users))
        .route("/api/admin/user/conversations", get(list_user_conversations))
        .route("/api/admin/conversations", get(list_conversations))
        .route("/api/admin/files", get(list_files))
        .route("/api/admin/messages", get(list_messages))
        .with_state(db)
}
