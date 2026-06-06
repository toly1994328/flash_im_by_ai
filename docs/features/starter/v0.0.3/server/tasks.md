# app-center — 后端任务清单

基于 server/design.md 设计，列出需要创建/修改的具体细节。
全局约束：错误处理使用 AppError，handler 返回 Result<Json<...>, AppError>。

---

## 执行顺序

1. ⬜ 任务 1 — Cargo.toml 配置（无依赖）
2. ⬜ 任务 2 — 数据库迁移脚本（无依赖）
3. ⬜ 任务 3 — models.rs 数据结构（依赖任务 1）
4. ⬜ 任务 4 — routes.rs 路由处理（依赖任务 3）
5. ⬜ 任务 5 — lib.rs 模块入口（依赖任务 4）
6. ⬜ 任务 6 — main.rs 注册路由（依赖任务 5）
7. ⬜ 任务 7 — 编译验证 + 测试

---

## 任务 1：Cargo.toml 配置 `⬜ 待处理`

### 1.1 新建 app-center 模块 Cargo.toml `⬜`

文件：`server/modules/app-center/Cargo.toml`（新建）

```toml
[package]
name = "app-center"
version = "0.1.0"
edition = "2024"

[dependencies]
axum.workspace = true
serde.workspace = true
serde_json.workspace = true
sqlx.workspace = true
```

### 1.2 注册到 workspace `⬜`

文件：`server/Cargo.toml`（修改）

在 `[workspace] members` 中添加 `"modules/app-center"`。

在根 crate 的 `[dependencies]` 中添加：
```toml
app-center = { path = "modules/app-center" }
```

---

## 任务 2：数据库迁移脚本 `⬜ 待处理`

文件：`server/migrations/20260605_create_app_tables.sql`（新建）

```sql
-- 应用注册表
CREATE TABLE IF NOT EXISTS apps (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 版本记录表
CREATE TABLE IF NOT EXISTS app_versions (
    id SERIAL PRIMARY KEY,
    app_id VARCHAR(64) NOT NULL REFERENCES apps(id),
    platform VARCHAR(32) NOT NULL,
    version VARCHAR(32) NOT NULL,
    download_url VARCHAR(512) NOT NULL,
    file_size BIGINT NOT NULL DEFAULT 0,
    sha256 VARCHAR(64),
    release_notes TEXT,
    force_update BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(app_id, platform, version)
);

CREATE INDEX IF NOT EXISTS idx_app_versions_lookup
    ON app_versions(app_id, platform, created_at DESC);

-- 插入闪讯应用
INSERT INTO apps (id, name, description) VALUES
    ('flash_im', '闪讯', '跨平台即时通讯应用')
ON CONFLICT (id) DO NOTHING;
```

---

## 任务 3：models.rs 数据结构 `⬜ 待处理`

文件：`server/modules/app-center/src/models.rs`（新建）

### 3.1 数据库行结构 `⬜`

```rust
#[derive(sqlx::FromRow, Serialize)]
pub struct AppVersionRow {
    pub version: String,
    pub download_url: String,
    pub file_size: i64,
    pub sha256: Option<String>,
    pub release_notes: Option<String>,
    pub force_update: bool,
}
```

### 3.2 查询参数 `⬜`

```rust
#[derive(Deserialize)]
pub struct VersionQuery {
    pub app_id: String,
    pub platform: String,
}
```

### 3.3 新增版本请求体 `⬜`

```rust
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
```

### 3.4 更新版本查询参数 + 请求体 `⬜`

```rust
#[derive(Deserialize)]
pub struct UpdateVersionQuery {
    pub app_id: String,
    pub platform: String,
    pub version: String,
}

#[derive(Deserialize)]
pub struct UpdateVersionPayload {
    pub download_url: Option<String>,
    pub file_size: Option<i64>,
    pub sha256: Option<String>,
    pub release_notes: Option<String>,
    pub force_update: Option<bool>,
}
```

---

## 任务 4：routes.rs 路由处理 `⬜ 待处理`

文件：`server/modules/app-center/src/routes.rs`（新建）

### 4.1 查询最新版本 `⬜`

```rust
pub async fn get_version(
    State(db): State<PgPool>,
    Query(params): Query<VersionQuery>,
) -> Result<Json<AppVersionRow>, AppError>
```

逻辑：
1. 校验 app_id 和 platform 非空
2. 查询 `SELECT version, download_url, file_size, sha256, release_notes, force_update FROM app_versions WHERE app_id=$1 AND platform=$2 ORDER BY created_at DESC LIMIT 1`
3. 找不到返回 404

### 4.2 新增版本 `⬜`

```rust
pub async fn create_version(
    State(db): State<PgPool>,
    Json(payload): Json<CreateVersionPayload>,
) -> Result<Json<serde_json::Value>, AppError>
```

逻辑：
1. 校验必填字段（app_id, platform, version, download_url）
2. INSERT INTO app_versions
3. UNIQUE 冲突返回 409

### 4.3 更新版本 `⬜`

```rust
pub async fn update_version(
    State(db): State<PgPool>,
    Query(params): Query<UpdateVersionQuery>,
    Json(payload): Json<UpdateVersionPayload>,
) -> Result<Json<serde_json::Value>, AppError>
```

逻辑：
1. 先查该版本是否存在，不存在返回 404
2. 用 payload 中非 None 的字段更新对应列
3. 返回成功

---

## 任务 5：lib.rs 模块入口 `⬜ 待处理`

文件：`server/modules/app-center/src/lib.rs`（新建）

```rust
mod models;
mod routes;

use axum::Router;
use axum::routing::{get, post, put};
use sqlx::PgPool;

pub fn router(db: PgPool) -> Router {
    Router::new()
        .route("/api/app/version", get(routes::get_version))
        .route("/api/app/version", post(routes::create_version))
        .route("/api/app/version", put(routes::update_version))
        .with_state(db)
}
```

---

## 任务 6：main.rs 注册路由 `⬜ 待处理`

文件：`server/src/main.rs`（修改）

在 Router 组装处添加：

```rust
.merge(app_center::router(db.clone()))
```

添加 use：
```rust
use app_center;
```

---

## 任务 7：编译验证 + 测试 `⬜ 待处理`

### 7.1 编译 `⬜`

```bash
cargo build
```

### 7.2 执行迁移 `⬜`

手动在 PostgreSQL 中执行迁移 SQL。

### 7.3 接口测试 `⬜`

```bash
# 新增版本
curl -X POST http://127.0.0.1:9600/api/app/version \
  -H "Content-Type: application/json" \
  -d '{"app_id":"flash_im","platform":"android","version":"1.0.0","download_url":"https://example.com/flash_im_1.0.0.apk","file_size":25000000,"sha256":"abc123","release_notes":"首个版本","force_update":false}'

# 查询最新版本
curl "http://127.0.0.1:9600/api/app/version?app_id=flash_im&platform=android"

# 更新版本信息
curl -X PUT "http://127.0.0.1:9600/api/app/version?app_id=flash_im&platform=android&version=1.0.0" \
  -H "Content-Type: application/json" \
  -d '{"release_notes":"更新说明修正","force_update":true}'

# 查询不存在的版本
curl "http://127.0.0.1:9600/api/app/version?app_id=flash_im&platform=ios"
```

预期：POST 返回 201，GET 返回 200，PUT 返回 200，不存在返回 404。
