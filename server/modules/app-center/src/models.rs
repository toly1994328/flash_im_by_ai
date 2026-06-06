use serde::{Deserialize, Serialize};

/// 版本查询结果（返回给客户端）
#[derive(sqlx::FromRow, Serialize)]
pub struct AppVersionRow {
    pub version: String,
    pub download_url: String,
    pub file_size: i64,
    pub sha256: Option<String>,
    pub release_notes: Option<String>,
    pub force_update: bool,
}

/// GET 查询参数
#[derive(Deserialize)]
pub struct VersionQuery {
    pub app_id: String,
    pub platform: String,
}

/// POST 新增版本请求体
#[derive(Deserialize)]
pub struct CreateVersionPayload {
    pub app_id: String,
    pub platform: String,
    pub version: String,
    pub download_url: String,
    pub file_size: Option<i64>,
    pub sha256: Option<String>,
    pub release_notes: Option<String>,
    pub force_update: Option<bool>,
}

/// PUT 更新查询参数
#[derive(Deserialize)]
pub struct UpdateVersionQuery {
    pub app_id: String,
    pub platform: String,
    pub version: String,
}

/// PUT 更新请求体（所有字段可选）
#[derive(Deserialize)]
pub struct UpdateVersionPayload {
    pub download_url: Option<String>,
    pub file_size: Option<i64>,
    pub sha256: Option<String>,
    pub release_notes: Option<String>,
    pub force_update: Option<bool>,
}

// ─── 管理接口模型 ───

#[derive(sqlx::FromRow, Serialize)]
pub struct AppRow {
    pub id: String,
    pub name: String,
    pub description: Option<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Deserialize)]
pub struct CreateAppPayload {
    pub id: String,
    pub name: String,
    pub description: Option<String>,
}

#[derive(Deserialize)]
pub struct AppIdQuery {
    pub app_id: String,
}

#[derive(sqlx::FromRow, Serialize)]
pub struct AppVersionFullRow {
    pub id: i32,
    pub platform: String,
    pub version: String,
    pub download_url: String,
    pub file_size: i64,
    pub sha256: Option<String>,
    pub release_notes: Option<String>,
    pub force_update: bool,
    pub created_at: chrono::DateTime<chrono::Utc>,
}
