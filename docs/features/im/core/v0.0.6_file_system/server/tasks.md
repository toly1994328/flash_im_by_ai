# app-storage 重构 — 服务端任务清单

基于 server/design.md 设计，列出需要创建/修改的具体细节。

全局约束：
- 错误处理使用 `AppError`，不使用 `StatusCode`
- 数据库访问用 sqlx，查询结果超过 3 字段用 `#[derive(FromRow)]` 结构体
- 分层：api.rs（handler）→ service.rs（业务逻辑）→ repository.rs（纯 SQL）
- messages.id 类型是 UUID，conversations.id 类型是 UUID，accounts.id 类型是 BIGINT

---

## 执行顺序

1. ✅ 任务 1 — 数据库迁移（新建 3 张表）
2. ✅ 任务 2 — Cargo.toml 添加依赖（sha1, sqlx, flash-core）
3. ✅ 任务 3 — StorageBackend trait + LocalFs 实现
4. ✅ 任务 4 — model.rs 数据结构定义
5. ✅ 任务 5 — repository.rs 数据库访问层
6. ✅ 任务 6 — service.rs 重构（去重 + 配额 + 存储编排）
7. ✅ 任务 7 — api.rs 重构（上传接口 + 配额查询 + 秒传 check）
8. ✅ 任务 8 — lib.rs 模块导出更新
9. ✅ 任务 9 — 注册流程扩展（创建配额记录）
10. ✅ 任务 10 — 消息发送时自动记录 file_references（从 content URL 反查 file_objects）
11. ✅ 任务 11 — 编译验证
12. ✅ 任务 12 — main.rs 适配（StorageService 构造 + WS 配额通知回调）
13. ✅ 任务 13 — 两步秒传接口（GET /api/storage/check）
14. ✅ 任务 14 — WS STORAGE_QUOTA_UPDATE 帧推送（proto + 回调 + tokio::spawn）

---

## 任务 1：数据库迁移 `⬜ 待处理`

文件：`server/migrations/20260616_016_file_system.sql`（新建）

### 1.1 创建 file_objects 表 `⬜`

```sql
CREATE TABLE IF NOT EXISTS file_objects (
    id            BIGSERIAL    PRIMARY KEY,
    hash          VARCHAR(40)  NOT NULL UNIQUE,
    storage_path  VARCHAR(500) NOT NULL,
    size          BIGINT       NOT NULL,
    mime_type     VARCHAR(100) NOT NULL,
    mime_category VARCHAR(20)  NOT NULL,
    width         INT,
    height        INT,
    duration_ms   BIGINT,
    thumb_path    VARCHAR(500),
    ref_count     INT          NOT NULL DEFAULT 1,
    uploader_id   BIGINT       NOT NULL REFERENCES accounts(id),
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_file_objects_hash ON file_objects(hash);
CREATE INDEX idx_file_objects_uploader ON file_objects(uploader_id);
```

### 1.2 创建 user_storage_quota 表 `⬜`

```sql
CREATE TABLE IF NOT EXISTS user_storage_quota (
    user_id     BIGINT       PRIMARY KEY REFERENCES accounts(id),
    used_bytes  BIGINT       NOT NULL DEFAULT 0,
    quota_bytes BIGINT       NOT NULL DEFAULT 104857600,
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
```

### 1.3 创建 file_references 表 `⬜`

```sql
CREATE TABLE IF NOT EXISTS file_references (
    id              BIGSERIAL   PRIMARY KEY,
    file_id         BIGINT      NOT NULL REFERENCES file_objects(id),
    message_id      UUID        NOT NULL REFERENCES messages(id),
    conversation_id UUID        NOT NULL,
    user_id         BIGINT      NOT NULL REFERENCES accounts(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_file_refs_file ON file_references(file_id);
CREATE INDEX idx_file_refs_message ON file_references(message_id);
CREATE INDEX idx_file_refs_conversation ON file_references(conversation_id);
```

### 1.4 为已有用户补建配额记录 `⬜`

```sql
INSERT INTO user_storage_quota (user_id, used_bytes, quota_bytes, updated_at)
SELECT id, 0, 104857600, NOW()
FROM accounts
WHERE id NOT IN (SELECT user_id FROM user_storage_quota);
```


---

## 任务 2：Cargo.toml 添加依赖 `⬜ 待处理`

文件：`server/modules/app-storage/Cargo.toml`（修改）

### 2.1 添加 sha1 和 sqlx 依赖 `⬜`

```toml
[dependencies]
axum.workspace = true
tokio.workspace = true
serde.workspace = true
serde_json.workspace = true
chrono.workspace = true
sqlx.workspace = true        # 新增
uuid = { version = "1", features = ["v4"] }
image = "0.25"
sha1 = "0.10"                # 新增
thiserror = "2"
```

说明：sqlx 用 workspace 版本统一管理；sha1 用于服务端校验客户端传来的 hash。

---

## 任务 3：StorageBackend trait + LocalFs 实现 `⬜ 待处理`

文件：`server/modules/app-storage/src/backend/mod.rs`（新建）
文件：`server/modules/app-storage/src/backend/local_fs.rs`（新建）

### 3.1 定义 StorageBackend trait `⬜`

文件：`src/backend/mod.rs`

```rust
pub mod local_fs;

use std::path::Path;

/// 存储后端抽象 trait
#[async_trait::trait]
// 注意：不引入 async_trait 宏，直接用 Rust 原生 async trait（edition 2024 支持）
pub trait StorageBackend: Send + Sync {
    /// 写入文件
    async fn put(&self, path: &str, data: &[u8]) -> Result<(), std::io::Error>;

    /// 读取文件
    async fn get(&self, path: &str) -> Result<Vec<u8>, std::io::Error>;

    /// 删除文件
    async fn delete(&self, path: &str) -> Result<(), std::io::Error>;

    /// 判断文件是否存在
    async fn exists(&self, path: &str) -> Result<bool, std::io::Error>;
}
```

### 3.2 实现 LocalFs `⬜`

文件：`src/backend/local_fs.rs`

```rust
use std::path::PathBuf;
use tokio::fs;
use super::StorageBackend;

/// 本地文件系统存储后端
pub struct LocalFs {
    base_path: PathBuf,
}

impl LocalFs {
    pub fn new(base_path: PathBuf) -> Self {
        Self { base_path }
    }
}

impl StorageBackend for LocalFs {
    async fn put(&self, path: &str, data: &[u8]) -> Result<(), std::io::Error> {
        // 1. 拼接完整路径: base_path / path
        // 2. 创建父目录: fs::create_dir_all
        // 3. 写入文件: fs::write
    }

    async fn get(&self, path: &str) -> Result<Vec<u8>, std::io::Error> {
        // fs::read(self.base_path.join(path))
    }

    async fn delete(&self, path: &str) -> Result<(), std::io::Error> {
        // fs::remove_file(self.base_path.join(path))
    }

    async fn exists(&self, path: &str) -> Result<bool, std::io::Error> {
        // Ok(self.base_path.join(path).exists())
    }
}
```


---

## 任务 4：model.rs 数据结构定义 `⬜ 待处理`

文件：`server/modules/app-storage/src/model.rs`（新建）

### 4.1 FileObject 结构体 `⬜`

```rust
use chrono::{DateTime, Utc};
use sqlx::FromRow;

#[derive(Debug, Clone, FromRow)]
pub struct FileObject {
    pub id: i64,
    pub hash: String,
    pub storage_path: String,
    pub size: i64,
    pub mime_type: String,
    pub mime_category: String,
    pub width: Option<i32>,
    pub height: Option<i32>,
    pub duration_ms: Option<i64>,
    pub thumb_path: Option<String>,
    pub ref_count: i32,
    pub uploader_id: i64,
    pub created_at: DateTime<Utc>,
}
```

### 4.2 UserStorageQuota 结构体 `⬜`

```rust
#[derive(Debug, Clone, FromRow)]
pub struct UserStorageQuota {
    pub user_id: i64,
    pub used_bytes: i64,
    pub quota_bytes: i64,
    pub updated_at: DateTime<Utc>,
}
```

### 4.3 CategoryUsage 聚合结果 `⬜`

```rust
#[derive(Debug, Clone, FromRow)]
pub struct CategoryUsage {
    pub mime_category: String,
    pub total_size: i64,
    pub file_count: i64,
}
```

### 4.4 上传请求/响应类型 `⬜`

```rust
use serde::Serialize;

/// 图片上传响应
#[derive(Debug, Serialize)]
pub struct ImageUploadResponse {
    pub file_id: i64,
    pub original_url: String,
    pub thumbnail_url: String,
    pub width: u32,
    pub height: u32,
    pub size: u64,
    pub format: String,
    pub is_dedup: bool,
}

/// 视频上传响应
#[derive(Debug, Serialize)]
pub struct VideoUploadResponse {
    pub file_id: i64,
    pub video_url: String,
    pub thumbnail_url: String,
    pub duration_ms: u64,
    pub width: u32,
    pub height: u32,
    pub file_size: u64,
    pub is_dedup: bool,
}

/// 文件上传响应
#[derive(Debug, Serialize)]
pub struct FileUploadResponse {
    pub file_id: i64,
    pub file_url: String,
    pub file_name: String,
    pub file_size: u64,
    pub file_type: String,
    pub is_dedup: bool,
}

/// 配额查询响应
#[derive(Debug, Serialize)]
pub struct QuotaResponse {
    pub used_bytes: i64,
    pub quota_bytes: i64,
    pub breakdown: std::collections::HashMap<String, CategoryDetail>,
}

#[derive(Debug, Serialize)]
pub struct CategoryDetail {
    pub size: i64,
    pub count: i64,
}
```


---

## 任务 5：repository.rs 数据库访问层 `⬜ 待处理`

文件：`server/modules/app-storage/src/repository.rs`（新建）

### 5.1 find_by_hash `⬜`

```rust
use sqlx::PgPool;
use crate::model::{FileObject, UserStorageQuota, CategoryUsage};

pub struct StorageRepo;

impl StorageRepo {
    /// 按 hash 查找文件对象
    pub async fn find_by_hash(db: &PgPool, hash: &str) -> Result<Option<FileObject>, sqlx::Error> {
        // SELECT * FROM file_objects WHERE hash = $1
    }
}
```

### 5.2 insert_file_object `⬜`

```rust
/// 插入新文件对象，返回完整记录
pub async fn insert_file_object(
    db: &PgPool,
    hash: &str,
    storage_path: &str,
    size: i64,
    mime_type: &str,
    mime_category: &str,
    width: Option<i32>,
    height: Option<i32>,
    duration_ms: Option<i64>,
    thumb_path: Option<&str>,
    uploader_id: i64,
) -> Result<FileObject, sqlx::Error> {
    // INSERT INTO file_objects (...) VALUES (...) RETURNING *
}
```

### 5.3 increment_ref_count `⬜`

```rust
/// ref_count += 1
pub async fn increment_ref_count(db: &PgPool, file_id: i64) -> Result<(), sqlx::Error> {
    // UPDATE file_objects SET ref_count = ref_count + 1 WHERE id = $1
}
```

### 5.4 decrement_ref_count `⬜`

```rust
/// ref_count -= 1（不低于 0）
pub async fn decrement_ref_count(db: &PgPool, file_id: i64) -> Result<(), sqlx::Error> {
    // UPDATE file_objects SET ref_count = GREATEST(ref_count - 1, 0) WHERE id = $1
}
```

### 5.5 get_quota `⬜`

```rust
/// 获取用户配额记录
pub async fn get_quota(db: &PgPool, user_id: i64) -> Result<Option<UserStorageQuota>, sqlx::Error> {
    // SELECT * FROM user_storage_quota WHERE user_id = $1
}
```

### 5.6 create_quota `⬜`

```rust
/// 创建用户配额记录（注册时调用）
pub async fn create_quota(db: &PgPool, user_id: i64) -> Result<(), sqlx::Error> {
    // INSERT INTO user_storage_quota (user_id) VALUES ($1) ON CONFLICT DO NOTHING
}
```

### 5.7 update_quota_used `⬜`

```rust
/// 增减配额已用量（delta 可正可负）
pub async fn update_quota_used(db: &PgPool, user_id: i64, delta: i64) -> Result<(), sqlx::Error> {
    // UPDATE user_storage_quota SET used_bytes = used_bytes + $2, updated_at = NOW() WHERE user_id = $1
}
```

### 5.8 get_usage_breakdown `⬜`

```rust
/// 按类型聚合用户文件用量
pub async fn get_usage_breakdown(db: &PgPool, user_id: i64) -> Result<Vec<CategoryUsage>, sqlx::Error> {
    // SELECT mime_category, COALESCE(SUM(size), 0::BIGINT) as total_size, COUNT(*) as file_count
    // FROM file_objects WHERE uploader_id = $1 GROUP BY mime_category
}
```

### 5.9 insert_reference `⬜`

```rust
/// 插入文件引用记录
pub async fn insert_reference(
    db: &PgPool,
    file_id: i64,
    message_id: uuid::Uuid,
    conversation_id: uuid::Uuid,
    user_id: i64,
) -> Result<(), sqlx::Error> {
    // INSERT INTO file_references (file_id, message_id, conversation_id, user_id) VALUES (...)
}
```

### 5.10 delete_references_by_message `⬜`

```rust
/// 删除某条消息的所有文件引用，返回涉及的 file_id 列表
pub async fn delete_references_by_message(
    db: &PgPool,
    message_id: uuid::Uuid,
) -> Result<Vec<i64>, sqlx::Error> {
    // DELETE FROM file_references WHERE message_id = $1 RETURNING file_id
}
```


---

## 任务 6：service.rs 重构 `⬜ 待处理`

文件：`server/modules/app-storage/src/service.rs`（重写）

### 6.1 StorageService 结构体重构 `⬜`

```rust
use std::sync::Arc;
use sqlx::PgPool;
use crate::backend::StorageBackend;
use crate::image::ImageProcessor;
use crate::model::*;
use crate::repository::StorageRepo;

pub struct StorageService {
    backend: Arc<dyn StorageBackend>,
    image_processor: ImageProcessor,
    config: StorageConfig,
    db: PgPool,
}

impl StorageService {
    pub fn new(
        backend: Arc<dyn StorageBackend>,
        config: StorageConfig,
        db: PgPool,
    ) -> Self {
        // 构建 ImageProcessor，保存 backend/config/db
    }
}
```

### 6.2 check_dedup 方法 `⬜`

```rust
/// 检查文件是否已存在（去重）
/// 已存在时：ref_count += 1，返回 Some(FileObject)
/// 不存在时：返回 None
pub async fn check_dedup(&self, hash: &str) -> Result<Option<FileObject>, AppError> {
    // 1. StorageRepo::find_by_hash(db, hash)
    // 2. 若存在：StorageRepo::increment_ref_count(db, file.id)
    // 3. 返回 Some(file) / None
}
```

### 6.3 check_quota 方法 `⬜`

```rust
/// 检查用户配额是否充足
/// 不足时返回 AppError::forbidden（含 used_bytes 和 quota_bytes）
pub async fn check_quota(&self, user_id: i64, file_size: i64) -> Result<(), AppError> {
    // 1. StorageRepo::get_quota(db, user_id)
    // 2. 若 quota.used_bytes + file_size > quota.quota_bytes → Err
    // 3. 否则 Ok(())
}
```

### 6.4 upload_image 方法重构 `⬜`

```rust
/// 上传图片（含去重 + 配额检查）
pub async fn upload_image(
    &self,
    data: &[u8],
    filename: &str,
    hash: &str,
    user_id: i64,
) -> Result<ImageUploadResponse, AppError> {
    // 1. check_dedup(hash) → 若已存在，直接返回 is_dedup=true
    // 2. 校验格式（jpg/png/gif/webp）+ 大小（≤10MB）
    // 3. check_quota(user_id, size)
    // 4. 生成存储路径: original/{yyyy/mm}/{uuid}.{ext}
    // 5. ImageProcessor.process(data) → (width, height, thumb_data)
    // 6. backend.put(original_path, data)
    // 7. backend.put(thumb_path, thumb_data)
    // 8. StorageRepo::insert_file_object(...)
    // 9. StorageRepo::update_quota_used(db, user_id, size)
    // 10. 返回 ImageUploadResponse { is_dedup: false, ... }
}
```

### 6.5 upload_video 方法重构 `⬜`

```rust
/// 上传视频（含去重 + 配额检查）
pub async fn upload_video(
    &self,
    video_data: &[u8],
    video_filename: &str,
    thumb_data: &[u8],
    hash: &str,
    user_id: i64,
    metadata: VideoUploadMetadata,
) -> Result<VideoUploadResponse, AppError> {
    // 1. check_dedup(hash) → 若已存在，直接返回 is_dedup=true
    // 2. 校验格式（mp4/mov/avi）+ 大小（≤50MB）
    // 3. check_quota(user_id, size)
    // 4. 生成路径: video/{yyyy/mm}/{uuid}.{ext}, thumb/{yyyy/mm}/{uuid}.jpg
    // 5. backend.put(video_path, video_data)
    // 6. backend.put(thumb_path, thumb_data)
    // 7. StorageRepo::insert_file_object(...) width/height/duration_ms
    // 8. StorageRepo::update_quota_used(db, user_id, size)
    // 9. 返回 VideoUploadResponse { is_dedup: false, ... }
}
```

### 6.6 upload_file 方法重构 `⬜`

```rust
/// 上传文件（含去重 + 配额检查）
pub async fn upload_file(
    &self,
    data: &[u8],
    filename: &str,
    hash: &str,
    user_id: i64,
) -> Result<FileUploadResponse, AppError> {
    // 1. check_dedup(hash) → 若已存在，直接返回 is_dedup=true
    // 2. 校验大小（≤50MB）
    // 3. check_quota(user_id, size)
    // 4. 生成路径: file/{yyyy/mm}/{uuid}.{ext}
    // 5. backend.put(file_path, data)
    // 6. StorageRepo::insert_file_object(...)
    // 7. StorageRepo::update_quota_used(db, user_id, size)
    // 8. 返回 FileUploadResponse { is_dedup: false, ... }
}
```

### 6.7 get_quota_info 方法 `⬜`

```rust
/// 查询用户配额和分类用量
pub async fn get_quota_info(&self, user_id: i64) -> Result<QuotaResponse, AppError> {
    // 1. StorageRepo::get_quota(db, user_id)
    // 2. StorageRepo::get_usage_breakdown(db, user_id)
    // 3. 组装 QuotaResponse { used_bytes, quota_bytes, breakdown }
}
```

### 6.8 add_reference / remove_reference 方法 `⬜`

```rust
/// 记录文件引用（消息发送后调用）
pub async fn add_reference(
    &self,
    file_id: i64,
    message_id: uuid::Uuid,
    conversation_id: uuid::Uuid,
    user_id: i64,
) -> Result<(), AppError> {
    // StorageRepo::insert_reference(db, file_id, message_id, conversation_id, user_id)
}

/// 移除文件引用（消息撤回时调用），同时减 ref_count
pub async fn remove_references_for_message(
    &self,
    message_id: uuid::Uuid,
) -> Result<(), AppError> {
    // 1. StorageRepo::delete_references_by_message(db, message_id) → file_ids
    // 2. 对每个 file_id: StorageRepo::decrement_ref_count(db, file_id)
}
```


---

## 任务 7：api.rs 重构 `⬜ 待处理`

文件：`server/modules/app-storage/src/api.rs`（重写）

### 7.1 upload_image handler 重构 `⬜`

```rust
use axum::{extract::{Multipart, State}, Json};
use flash_core::{AppError, jwt::extract_user_id};
use std::sync::Arc;
use crate::service::StorageService;
use crate::model::ImageUploadResponse;

/// POST /api/upload/image
/// multipart fields: file (图片), hash (SHA-1 hex)
async fn upload_image(
    State(storage): State<Arc<StorageService>>,
    headers: axum::http::HeaderMap,
    mut multipart: Multipart,
) -> Result<Json<ImageUploadResponse>, AppError> {
    // 1. extract_user_id(&headers)
    // 2. 遍历 multipart fields，提取 file(bytes + filename) 和 hash(text)
    // 3. 调用 storage.upload_image(data, filename, hash, user_id)
    // 4. 返回 Json(response)
}
```

### 7.2 upload_video handler 重构 `⬜`

```rust
/// POST /api/upload/video
/// multipart fields: video, thumbnail, hash, duration_ms, width, height
async fn upload_video(
    State(storage): State<Arc<StorageService>>,
    headers: axum::http::HeaderMap,
    mut multipart: Multipart,
) -> Result<Json<VideoUploadResponse>, AppError> {
    // 1. extract_user_id(&headers)
    // 2. 遍历 multipart fields，提取 video/thumbnail/hash/metadata
    // 3. 调用 storage.upload_video(...)
    // 4. 返回 Json(response)
}
```

### 7.3 upload_file handler 重构 `⬜`

```rust
/// POST /api/upload/file
/// multipart fields: file, hash
async fn upload_file(
    State(storage): State<Arc<StorageService>>,
    headers: axum::http::HeaderMap,
    mut multipart: Multipart,
) -> Result<Json<FileUploadResponse>, AppError> {
    // 1. extract_user_id(&headers)
    // 2. 遍历 multipart fields，提取 file(bytes + filename) 和 hash(text)
    // 3. 调用 storage.upload_file(data, filename, hash, user_id)
    // 4. 返回 Json(response)
}
```

### 7.4 get_quota handler 新增 `⬜`

```rust
/// GET /api/storage/quota
async fn get_quota(
    State(storage): State<Arc<StorageService>>,
    headers: axum::http::HeaderMap,
) -> Result<Json<QuotaResponse>, AppError> {
    // 1. extract_user_id(&headers)
    // 2. storage.get_quota_info(user_id)
    // 3. 返回 Json(response)
}
```

### 7.5 路由注册更新 `⬜`

```rust
use axum::{routing::{get, post}, Router};
use axum::extract::DefaultBodyLimit;

pub fn storage_routes(storage: Arc<StorageService>) -> Router {
    let video_limit = storage.max_video_size() as usize;
    let file_limit = storage.max_file_size() as usize;
    Router::new()
        .route("/api/upload/image", post(upload_image))
        .route("/api/upload/video", post(upload_video).layer(DefaultBodyLimit::max(video_limit)))
        .route("/api/upload/file", post(upload_file).layer(DefaultBodyLimit::max(file_limit)))
        .route("/api/storage/quota", get(get_quota))
        .with_state(storage)
}
```


---

## 任务 8：lib.rs 模块导出更新 `⬜ 待处理`

文件：`server/modules/app-storage/src/lib.rs`（修改）

### 8.1 更新模块声明和导出 `⬜`

```rust
pub mod api;
pub mod backend;
pub mod image;
pub mod model;
pub mod repository;
pub mod service;

pub use service::{StorageConfig, StorageService};
pub use backend::{StorageBackend, local_fs::LocalFs};
```

---

## 任务 9：注册流程扩展 `⬜ 待处理`

文件：`server/modules/flash-auth/src/handler.rs`（修改）
文件：`server/modules/flash-auth/src/oauth/mod.rs`（修改）

### 9.1 手机号注册时创建配额记录 `⬜`

在 `handler.rs` 中 INSERT INTO accounts 之后（事务内），追加：

```rust
sqlx::query(
    "INSERT INTO user_storage_quota (user_id) VALUES ($1)"
)
.bind(account_id)
.execute(&mut *tx)
.await?;
```

注意：有 3 处注册点需要添加：
1. `handler.rs` 中手机号注册（约第 332 行后）
2. `handler.rs` 中邮箱注册（约第 445 行后）
3. `oauth/mod.rs` 中 OAuth 注册（约第 47 行后）

### 9.2 确认事务中添加 `⬜`

三处注册都在 `tx` 事务中，直接用 `&mut *tx` 执行即可，无需额外处理。

---

## 任务 10：消息撤回扩展 `⬜ 待处理`

文件：需要先确认消息撤回的代码位置

### 10.1 在撤回逻辑中调用 remove_references `⬜`

消息撤回处理位于 `im-message` 模块的 routes 中。撤回成功后需要：

```rust
// 在 recall 成功（UPDATE messages SET is_recalled = true）之后添加：
// 调用 StorageService.remove_references_for_message(message_id)
```

实现方式：
1. `im-message` 的 routes 中需要引入 `StorageService`（通过 AppState 共享）
2. 在 recall handler 中，撤回成功后调用 `storage.remove_references_for_message(message_id).await`
3. 这步是 best-effort：如果失败只打日志，不影响撤回本身

### 10.2 发送消息时记录引用 `⬜`

在 `im-message` 的消息发送流程中，如果消息类型是 IMAGE/VIDEO/FILE/AUDIO：
- 从消息的 extra 或 content 中提取 file_id
- 调用 `storage.add_reference(file_id, message_id, conversation_id, sender_id)`

注意：这需要前端在发送消息时把 `file_id`（上传返回的）传到后端。可以放在 proto 的 extra 字段中。

如果改动面太大，可以暂时跳过此步骤——file_references 表先不填数据，等前端配合改好 proto 后统一补录。

---

## 任务 11：编译验证 `⬜ 待处理`

### 11.1 cargo build 编译通过 `⬜`

```bash
cd server && cargo build
```

确认无编译错误。

### 11.2 运行数据库迁移 `⬜`

```bash
python scripts/server/reset_db.py
# 或手动执行 migrations/20260616_016_file_system.sql
```

### 11.3 启动服务测试 `⬜`

```bash
python scripts/server/start.py
```

用 curl 手动验证：
- `curl -X POST /api/upload/image`（带 file + hash）→ 返回 file_id
- 相同 hash 再传一次 → is_dedup=true
- `GET /api/storage/quota` → 返回用量信息

---

## 任务 12：main.rs 适配 `⬜ 待处理`

文件：`server/src/main.rs`（修改）

### 12.1 StorageService 构造方式更新 `⬜`

原代码：
```rust
let storage = Arc::new(StorageService::new(StorageConfig::from_env()));
```

改为：
```rust
let storage_config = StorageConfig::from_env();
let local_fs = Arc::new(LocalFs::new(storage_config.base_path.clone()));
let storage = Arc::new(StorageService::new(local_fs, storage_config, db.clone()));
```

需要新增 import：
```rust
use app_storage::LocalFs;
```

### 12.2 更新执行顺序 `⬜`

将任务 12 插入到任务 11 之前。最终执行顺序：
1~10 → 12（main.rs 适配）→ 11（编译验证）
