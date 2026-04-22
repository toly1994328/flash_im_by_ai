use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use axum::Json;

/// 统一应用错误类型
///
/// 所有 crate 的 handler 返回 `Result<..., AppError>` 即可自动：
/// 1. 在服务端日志打印错误详情（含来源）
/// 2. 给客户端返回结构化的 JSON 错误响应
///
/// # 用法
///
/// ```rust
/// // 从 StatusCode 创建（无详情）
/// return Err(AppError::status(StatusCode::FORBIDDEN));
///
/// // 带消息
/// return Err(AppError::bad_request("群名不能为空"));
///
/// // 从 sqlx::Error 自动转换
/// let rows = sqlx::query("...").fetch_all(&db).await?;  // 自动转为 500 + 打印错误
///
/// // 带上下文
/// repo.do_something().await.map_err(|e| AppError::internal(e, "add_members"))?;
/// ```
#[derive(Debug)]
pub struct AppError {
    pub status: StatusCode,
    pub message: String,
    /// 内部错误详情（只打印到服务端日志，不返回给客户端）
    pub detail: Option<String>,
}

impl AppError {
    /// 从 StatusCode 创建（无详情）
    pub fn status(status: StatusCode) -> Self {
        Self {
            message: status.canonical_reason().unwrap_or("Unknown error").to_string(),
            status,
            detail: None,
        }
    }

    /// 400 Bad Request
    pub fn bad_request(msg: impl Into<String>) -> Self {
        Self { status: StatusCode::BAD_REQUEST, message: msg.into(), detail: None }
    }

    /// 403 Forbidden
    pub fn forbidden(msg: impl Into<String>) -> Self {
        Self { status: StatusCode::FORBIDDEN, message: msg.into(), detail: None }
    }

    /// 404 Not Found
    pub fn not_found(msg: impl Into<String>) -> Self {
        Self { status: StatusCode::NOT_FOUND, message: msg.into(), detail: None }
    }

    /// 500 Internal Server Error（带上下文标签）
    pub fn internal(err: impl std::fmt::Display, context: &str) -> Self {
        let detail = format!("[{}] {}", context, err);
        Self {
            status: StatusCode::INTERNAL_SERVER_ERROR,
            message: "Internal Server Error".to_string(),
            detail: Some(detail),
        }
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        // 服务端日志：打印所有错误（含内部详情）
        if let Some(ref detail) = self.detail {
            println!("❌ {}", detail);
        } else if self.status.is_server_error() {
            println!("❌ [{}] {}", self.status.as_u16(), self.message);
        }

        // 客户端响应：结构化 JSON
        let mut body = serde_json::json!({
            "error": self.message,
            "status": self.status.as_u16(),
        });

        // 内部错误详情也返回给客户端，方便排查
        if let Some(ref detail) = self.detail {
            body["detail"] = serde_json::Value::String(detail.clone());
        }

        (self.status, Json(body)).into_response()
    }
}

/// 从 sqlx::Error 自动转换（500 + 打印详情）
impl From<sqlx::Error> for AppError {
    fn from(err: sqlx::Error) -> Self {
        AppError::internal(err, "database")
    }
}

/// 从 StatusCode 自动转换（兼容旧代码）
impl From<StatusCode> for AppError {
    fn from(status: StatusCode) -> Self {
        AppError::status(status)
    }
}
