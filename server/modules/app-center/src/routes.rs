use axum::extract::{Query, State};
use axum::http::StatusCode;
use axum::Json;
use sqlx::PgPool;
use flash_core::AppError;

use crate::models::*;

/// GET /api/app/version — 查询最新版本
pub async fn get_version(
    State(db): State<PgPool>,
    Query(params): Query<VersionQuery>,
) -> Result<Json<AppVersionRow>, AppError> {
    if params.app_id.is_empty() || params.platform.is_empty() {
        return Err(AppError::bad_request("app_id and platform are required"));
    }

    let row = sqlx::query_as::<_, AppVersionRow>(
        r"SELECT version, download_url, file_size, sha256, release_notes, force_update
          FROM app_versions
          WHERE app_id = $1 AND platform = $2 AND published = true
          ORDER BY created_at DESC
          LIMIT 1"
    )
    .bind(&params.app_id)
    .bind(&params.platform)
    .fetch_optional(&db)
    .await?;

    match row {
        Some(v) => Ok(Json(v)),
        None => Err(AppError::not_found("no version found")),
    }
}

/// POST /api/app/version — 新增版本记录
pub async fn create_version(
    State(db): State<PgPool>,
    Json(payload): Json<CreateVersionPayload>,
) -> Result<(StatusCode, Json<serde_json::Value>), AppError> {
    if payload.app_id.is_empty() || payload.platform.is_empty()
        || payload.version.is_empty() || payload.download_url.is_empty()
    {
        return Err(AppError::bad_request("app_id, platform, version, download_url are required"));
    }

    let result = sqlx::query(
        r"INSERT INTO app_versions (app_id, platform, version, download_url, file_size, sha256, release_notes, force_update)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8)"
    )
    .bind(&payload.app_id)
    .bind(&payload.platform)
    .bind(&payload.version)
    .bind(&payload.download_url)
    .bind(payload.file_size.unwrap_or(0))
    .bind(&payload.sha256)
    .bind(&payload.release_notes)
    .bind(payload.force_update.unwrap_or(false))
    .execute(&db)
    .await;

    match result {
        Ok(_) => Ok((StatusCode::CREATED, Json(serde_json::json!({"message": "version created"})))),
        Err(e) if e.to_string().contains("duplicate key") => {
            Err(AppError::bad_request("version already exists"))
        }
        Err(e) => Err(AppError::internal(e, "create_version")),
    }
}

/// PUT /api/app/version — 更新已有版本信息
pub async fn update_version(
    State(db): State<PgPool>,
    Query(params): Query<UpdateVersionQuery>,
    Json(payload): Json<UpdateVersionPayload>,
) -> Result<Json<serde_json::Value>, AppError> {
    // 先检查版本是否存在
    let exists = sqlx::query_scalar::<_, i32>(
        r"SELECT id FROM app_versions WHERE app_id = $1 AND platform = $2 AND version = $3"
    )
    .bind(&params.app_id)
    .bind(&params.platform)
    .bind(&params.version)
    .fetch_optional(&db)
    .await?;

    if exists.is_none() {
        return Err(AppError::not_found("version not found"));
    }

    // 动态构建 SET 子句
    let mut sets = Vec::new();
    let mut idx = 4u32; // $1=$app_id, $2=$platform, $3=$version

    if payload.download_url.is_some() { sets.push(format!("download_url = ${idx}")); idx += 1; }
    if payload.file_size.is_some() { sets.push(format!("file_size = ${idx}")); idx += 1; }
    if payload.sha256.is_some() { sets.push(format!("sha256 = ${idx}")); idx += 1; }
    if payload.release_notes.is_some() { sets.push(format!("release_notes = ${idx}")); idx += 1; }
    if payload.force_update.is_some() { sets.push(format!("force_update = ${idx}")); }

    if sets.is_empty() {
        return Ok(Json(serde_json::json!({"message": "nothing to update"})));
    }

    let sql = format!(
        "UPDATE app_versions SET {} WHERE app_id = $1 AND platform = $2 AND version = $3",
        sets.join(", ")
    );

    let mut query = sqlx::query(&sql)
        .bind(&params.app_id)
        .bind(&params.platform)
        .bind(&params.version);

    if let Some(ref v) = payload.download_url { query = query.bind(v); }
    if let Some(v) = payload.file_size { query = query.bind(v); }
    if let Some(ref v) = payload.sha256 { query = query.bind(v); }
    if let Some(ref v) = payload.release_notes { query = query.bind(v); }
    if let Some(v) = payload.force_update { query = query.bind(v); }

    query.execute(&db).await?;

    Ok(Json(serde_json::json!({"message": "version updated"})))
}

// ─── 管理接口 ───

/// GET /api/app/list — 获取所有应用
pub async fn list_apps(
    State(db): State<PgPool>,
) -> Result<Json<Vec<AppRow>>, AppError> {
    let rows = sqlx::query_as::<_, AppRow>(
        "SELECT id, name, description, created_at FROM apps ORDER BY created_at"
    )
    .fetch_all(&db)
    .await?;

    Ok(Json(rows))
}

/// POST /api/app — 新增应用
pub async fn create_app(
    State(db): State<PgPool>,
    Json(payload): Json<CreateAppPayload>,
) -> Result<(StatusCode, Json<serde_json::Value>), AppError> {
    if payload.id.is_empty() || payload.name.is_empty() {
        return Err(AppError::bad_request("id and name are required"));
    }

    let result = sqlx::query(
        "INSERT INTO apps (id, name, description) VALUES ($1, $2, $3)"
    )
    .bind(&payload.id)
    .bind(&payload.name)
    .bind(&payload.description)
    .execute(&db)
    .await;

    match result {
        Ok(_) => Ok((StatusCode::CREATED, Json(serde_json::json!({"message": "app created"})))),
        Err(e) if e.to_string().contains("duplicate key") => {
            Err(AppError::bad_request("app already exists"))
        }
        Err(e) => Err(AppError::internal(e, "create_app")),
    }
}

/// GET /api/app/versions — 获取某应用的全部版本记录
pub async fn list_versions(
    State(db): State<PgPool>,
    Query(params): Query<AppIdQuery>,
) -> Result<Json<Vec<AppVersionFullRow>>, AppError> {
    if params.app_id.is_empty() {
        return Err(AppError::bad_request("app_id is required"));
    }

    let rows = sqlx::query_as::<_, AppVersionFullRow>(
        r"SELECT id, platform, version, download_url, file_size, sha256, release_notes, force_update, published, created_at
          FROM app_versions
          WHERE app_id = $1
          ORDER BY created_at DESC"
    )
    .bind(&params.app_id)
    .fetch_all(&db)
    .await?;

    Ok(Json(rows))
}


/// POST /api/app/version/publish — 发布版本
pub async fn publish_version(
    State(db): State<PgPool>,
    Query(params): Query<PublishQuery>,
) -> Result<Json<serde_json::Value>, AppError> {
    let result = sqlx::query(
        "UPDATE app_versions SET published = true WHERE app_id = $1 AND platform = $2 AND version = $3"
    )
    .bind(&params.app_id)
    .bind(&params.platform)
    .bind(&params.version)
    .execute(&db)
    .await?;

    if result.rows_affected() == 0 {
        return Err(AppError::not_found("version not found"));
    }
    Ok(Json(serde_json::json!({"message": "version published"})))
}

/// POST /api/app/version/unpublish — 撤回发布
pub async fn unpublish_version(
    State(db): State<PgPool>,
    Query(params): Query<PublishQuery>,
) -> Result<Json<serde_json::Value>, AppError> {
    let result = sqlx::query(
        "UPDATE app_versions SET published = false WHERE app_id = $1 AND platform = $2 AND version = $3"
    )
    .bind(&params.app_id)
    .bind(&params.platform)
    .bind(&params.version)
    .execute(&db)
    .await?;

    if result.rows_affected() == 0 {
        return Err(AppError::not_found("version not found"));
    }
    Ok(Json(serde_json::json!({"message": "version unpublished"})))
}


/// DELETE /api/app/version — 删除版本记录
pub async fn delete_version(
    State(db): State<PgPool>,
    Query(params): Query<PublishQuery>,
) -> Result<Json<serde_json::Value>, AppError> {
    let result = sqlx::query(
        "DELETE FROM app_versions WHERE app_id = $1 AND platform = $2 AND version = $3"
    )
    .bind(&params.app_id)
    .bind(&params.platform)
    .bind(&params.version)
    .execute(&db)
    .await?;

    if result.rows_affected() == 0 {
        return Err(AppError::not_found("version not found"));
    }
    Ok(Json(serde_json::json!({"message": "version deleted"})))
}
