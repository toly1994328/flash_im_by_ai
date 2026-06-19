# 云空间 Tab — 服务端任务清单

基于 server/design.md，在现有 app-storage 模块上新增 3 个接口。

---

## 执行顺序

1. ✅ 任务 1 — model.rs 新增响应结构体（含 original_name 字段）
2. ✅ 任务 2 — repository.rs 新增查询方法（insert_file_object 加 original_name 参数）
3. ✅ 任务 3 — service.rs 新增 delete_file 方法 + truncate_filename 工具函数
4. ✅ 任务 4 — api.rs 新增 3 个 handler + 路由
5. ✅ 任务 5 — 编译验证
6. ✅ 任务 6 — file_objects 表新增 original_name 字段 + 上传时存储
7. ✅ 任务 7 — main.rs: /uploads 从 CompressionLayer 中移出（保留 Content-Length）

---

## 任务 1：model.rs 新增响应结构体 `⬜`

文件：`server/modules/app-storage/src/model.rs`（修改）

### 1.1 FileListResponse `⬜`

```rust
#[derive(Debug, Serialize)]
pub struct FileListResponse {
    pub data: Vec<FileListItem>,
    pub total: i64,
    pub page: i64,
    pub limit: i64,
}

#[derive(Debug, Serialize)]
pub struct FileListItem {
    pub id: i64,
    pub url: String,
    pub thumb_url: Option<String>,
    pub size: i64,
    pub mime_type: String,
    pub mime_category: String,
    pub width: Option<i32>,
    pub height: Option<i32>,
    pub duration_ms: Option<i64>,
    pub ref_count: i32,
    pub created_at: chrono::DateTime<chrono::Utc>,
}
```

### 1.2 FileDetailResponse `⬜`

```rust
#[derive(Debug, Serialize)]
pub struct FileDetailResponse {
    pub file: FileListItem,
    pub conversations: Vec<FileConversationRef>,
}

#[derive(Debug, Serialize)]
pub struct FileConversationRef {
    pub conversation_id: String,
    pub conversation_name: String,
    pub conversation_type: i16,
    pub avatar: Option<String>,
    pub message_count: i64,
}
```

### 1.3 FileDeleteResponse `⬜`

```rust
#[derive(Debug, Serialize)]
pub struct FileDeleteResponse {
    pub message: String,
    pub freed_bytes: i64,
    pub new_used_bytes: i64,
    pub new_quota_bytes: i64,
}
```

---

## 任务 2：repository.rs 新增查询方法 `⬜`

文件：`server/modules/app-storage/src/repository.rs`（修改）

### 2.1 list_files `⬜`

```rust
/// 分页查询用户文件列表
pub async fn list_files(
    db: &PgPool,
    user_id: i64,
    category: Option<&str>,
    page: i64,
    limit: i64,
) -> Result<(Vec<FileObject>, i64), sqlx::Error> {
    // 动态构建 SQL：WHERE uploader_id = $1 [AND mime_category = $2]
    // ORDER BY created_at DESC LIMIT $limit OFFSET (page-1)*limit
    // 同时查 COUNT(*) 得到 total
}
```

### 2.2 get_file_by_id `⬜`

```rust
/// 按 ID 查询文件（校验 uploader_id）
pub async fn get_file_by_id(
    db: &PgPool,
    file_id: i64,
    user_id: i64,
) -> Result<Option<FileObject>, sqlx::Error> {
    // SELECT * FROM file_objects WHERE id = $1 AND uploader_id = $2
}
```

### 2.3 get_file_conversations `⬜`

```rust
/// 查询文件被哪些会话引用
pub async fn get_file_conversations(
    db: &PgPool,
    file_id: i64,
) -> Result<Vec<FileConvRow>, sqlx::Error> {
    // SELECT m.conversation_id, c.type, COUNT(*) as message_count
    // FROM file_references fr
    // JOIN messages m ON m.id = fr.message_id
    // JOIN conversations c ON c.id = m.conversation_id
    // WHERE fr.file_id = $1
    // GROUP BY m.conversation_id, c.type
}

#[derive(Debug, FromRow)]
pub struct FileConvRow {
    pub conversation_id: Uuid,
    pub r#type: i16,
    pub message_count: i64,
}
```

### 2.4 delete_file_object `⬜`

```rust
/// 物理删除 file_objects 记录
pub async fn delete_file_object(db: &PgPool, file_id: i64) -> Result<(), sqlx::Error> {
    // DELETE FROM file_objects WHERE id = $1
}
```

---

## 任务 3：service.rs 新增 delete_file 方法 `⬜`

文件：`server/modules/app-storage/src/service.rs`（修改）

### 3.1 delete_file `⬜`

```rust
/// 删除文件
/// ref_count > 1: 只减计数
/// ref_count = 1: 物理删除文件 + 删 DB 记录 + 回收配额 + 通知
pub async fn delete_file(&self, file_id: i64, user_id: i64) -> Result<FileDeleteResponse, StorageError> {
    // 1. get_file_by_id(db, file_id, user_id) → 404 或 403
    // 2. if ref_count > 1: decrement_ref_count → return freed=0
    // 3. if ref_count == 1:
    //    a. delete_references_by_file(file_id)  ← 新方法
    //    b. backend.delete(storage_path)
    //    c. if thumb_path: backend.delete(thumb_path)
    //    d. delete_file_object(db, file_id)
    //    e. update_quota_used(db, user_id, -file.size)
    //    f. notify_quota_changed(...)
    //    g. return freed=file.size
}
```

### 3.2 repository 补充 delete_references_by_file `⬜`

```rust
/// 删除某文件的所有引用记录
pub async fn delete_references_by_file(db: &PgPool, file_id: i64) -> Result<(), sqlx::Error> {
    // DELETE FROM file_references WHERE file_id = $1
}
```

---

## 任务 4：api.rs 新增 handler + 路由 `⬜`

文件：`server/modules/app-storage/src/api.rs`（修改）

### 4.1 list_files handler `⬜`

```rust
#[derive(Deserialize)]
struct FileListQuery {
    category: Option<String>,
    page: Option<i64>,
    limit: Option<i64>,
}

/// GET /api/storage/files
async fn list_files(
    State(storage): State<Arc<AppStorageService>>,
    headers: HeaderMap,
    Query(query): Query<FileListQuery>,
) -> Result<Json<FileListResponse>, AppError> {
    // extract_user_id → 调用 repository.list_files → 组装响应
}
```

### 4.2 file_detail handler `⬜`

```rust
/// GET /api/storage/files/{id}
async fn file_detail(
    State(storage): State<Arc<AppStorageService>>,
    headers: HeaderMap,
    Path(file_id): Path<i64>,
) -> Result<Json<FileDetailResponse>, AppError> {
    // 1. get_file_by_id → 404
    // 2. get_file_conversations → 查会话名称
    // 3. 组装响应
}
```

### 4.3 delete_file handler `⬜`

```rust
/// DELETE /api/storage/files/{id}
async fn delete_file_handler(
    State(storage): State<Arc<AppStorageService>>,
    headers: HeaderMap,
    Path(file_id): Path<i64>,
) -> Result<Json<FileDeleteResponse>, AppError> {
    // extract_user_id → storage.delete_file(file_id, user_id)
}
```

### 4.4 路由注册 `⬜`

```rust
.route("/api/storage/files", get(list_files))
.route("/api/storage/files/{id}", get(file_detail).delete(delete_file_handler))
```

---

## 任务 5：编译验证 `⬜`

```bash
cargo build
```
