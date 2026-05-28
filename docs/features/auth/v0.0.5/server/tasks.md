# Auth — 后端任务清单（扫码登录）

基于 server/design.md 设计，列出需要创建/修改的具体细节。
错误处理使用 AppError，不使用裸 StatusCode。uuid crate 需新增依赖。

---

## 执行顺序

1. ⬜ 任务 1 — 新建迁移文件 scan_sessions 表（无依赖）
2. ⬜ 任务 2 — 添加 uuid 依赖（无依赖）
3. ⬜ 任务 3 — model.rs 新增请求/响应结构体（无依赖）
4. ⬜ 任务 4 — handler.rs 新增 4 个 handler 函数（依赖任务 2、3）
5. ⬜ 任务 5 — routes.rs 注册新路由（依赖任务 4）
6. ⬜ 任务 6 — 编译验证

---

## 任务 1：scan_sessions 迁移 `⬜ 待处理`

文件：`server/migrations/20260528_013_scan_sessions.sql`（新建）

### 1.1 建表 SQL `⬜`

```sql
CREATE TABLE IF NOT EXISTS scan_sessions (
    token       VARCHAR(36) PRIMARY KEY,
    status      SMALLINT NOT NULL DEFAULT 0,  -- 0=pending 1=scanned 2=confirmed 3=cancelled
    user_id     BIGINT,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 任务 2：添加 uuid 依赖 `⬜ 待处理`

文件：`server/modules/flash-auth/Cargo.toml`（修改）

### 2.1 添加 uuid crate `⬜`

在 `[dependencies]` 中添加：

```toml
uuid = { version = "1", features = ["v4"] }
```

---

## 任务 3：model.rs — 新增 Scan 结构体 `⬜ 待处理`

文件：`server/modules/flash-auth/src/model.rs`（修改）

### 3.1 新增请求结构体 `⬜`

```rust
/// 扫码创建响应
#[derive(Serialize)]
pub struct ScanCreateResponse {
    pub token: String,
    pub qr_content: String,
    pub expires_at: chrono::DateTime<chrono::Utc>,
}

/// 扫码状态响应
#[derive(Serialize)]
pub struct ScanStatusResponse {
    pub status: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub token: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub user_id: Option<i64>,
}

/// 扫码确认请求
#[derive(Deserialize)]
pub struct ScanConfirmRequest {
    pub scan_token: String,
    pub action: String,  // "scan" 或 "confirm"
}

/// 扫码取消请求
#[derive(Deserialize)]
pub struct ScanCancelRequest {
    pub scan_token: String,
}
```

---

## 任务 4：handler.rs — 新增 4 个 handler `⬜ 待处理`

文件：`server/modules/flash-auth/src/handler.rs`（修改）

### 4.1 scan_create — 创建扫码会话 `⬜`

```rust
/// POST /auth/scan/create
pub async fn scan_create(
    State(state): State<Arc<AppState>>,
) -> Result<Json<ScanCreateResponse>, AppError>
```

逻辑步骤：
1. 生成 UUID token：`uuid::Uuid::new_v4().to_string()`
2. 计算 expires_at = now + 5 分钟
3. INSERT INTO scan_sessions (token, status, expires_at) VALUES ($1, 0, $2)
4. 构造 qr_content = `format!("flash://scan/{}", token)`
5. 返回 ScanCreateResponse

### 4.2 scan_status — 查询扫码状态 `⬜`

```rust
/// GET /auth/scan/status?token=xxx
pub async fn scan_status(
    State(state): State<Arc<AppState>>,
    Query(params): Query<HashMap<String, String>>,
) -> Result<Json<ScanStatusResponse>, AppError>
```

逻辑步骤：
1. 从 query params 取 token，缺失返回 bad_request
2. SELECT status, user_id, expires_at FROM scan_sessions WHERE token = $1
3. 不存在返回 not_found
4. 如果 now > expires_at 且 status < 2，返回 `{ status: "expired" }`
5. 根据 status 值映射：0=pending, 1=scanned, 2=confirmed, 3=cancelled
6. status=confirmed 时额外返回 JWT token（用 user_id 调 generate_token）和 user_id

### 4.3 scan_confirm — 扫码/确认 `⬜`

```rust
/// POST /auth/scan/confirm
pub async fn scan_confirm(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<ScanConfirmRequest>,
) -> Result<Json<serde_json::Value>, AppError>
```

逻辑步骤：
1. extract_user_id(&headers) 获取手机端 user_id，失败返回 401
2. SELECT status, expires_at FROM scan_sessions WHERE token = $1
3. 不存在或已过期返回 bad_request
4. action == "scan"：
   - 校验 status == 0（pending），否则返回 409 conflict
   - UPDATE scan_sessions SET status = 1, user_id = $1 WHERE token = $2
5. action == "confirm"：
   - 校验 status == 1（scanned），否则返回 409
   - 校验 user_id 匹配
   - UPDATE scan_sessions SET status = 2 WHERE token = $1
6. 返回 `{ "message": "ok" }`

### 4.4 scan_cancel — 取消 `⬜`

```rust
/// POST /auth/scan/cancel
pub async fn scan_cancel(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<ScanCancelRequest>,
) -> Result<Json<serde_json::Value>, AppError>
```

逻辑步骤：
1. extract_user_id(&headers) 获取 user_id
2. SELECT status, user_id FROM scan_sessions WHERE token = $1
3. 校验 status == 1 且 user_id 匹配
4. UPDATE scan_sessions SET status = 3 WHERE token = $1
5. 返回 `{ "message": "ok" }`

---

## 任务 5：routes.rs — 注册路由 `⬜ 待处理`

文件：`server/modules/flash-auth/src/routes.rs`（修改）

### 5.1 新增路由注册 `⬜`

```rust
use axum::routing::get;
use super::handler::{scan_create, scan_status, scan_confirm, scan_cancel};

// 在 router() 中添加：
.route("/auth/scan/create", post(scan_create))
.route("/auth/scan/status", get(scan_status))
.route("/auth/scan/confirm", post(scan_confirm))
.route("/auth/scan/cancel", post(scan_cancel))
```

---

## 任务 6：编译验证 `⬜ 待处理`

### 6.1 cargo build `⬜`

执行 `cargo build`，确保零错误。

### 6.2 重置数据库 `⬜`

执行 `python scripts/server/reset_db.py`，确保新表创建成功。

### 6.3 启动服务验证 `⬜`

执行 `python scripts/server/start.py`，确保服务正常启动。
