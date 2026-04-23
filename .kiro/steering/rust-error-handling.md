---
inclusion: fileMatch
fileMatchPattern: "server/**/*.rs"
---

# Rust 后端错误处理规范

## AppError

项目已有统一错误类型 `flash_core::AppError`，位于 `server/modules/flash-core/src/error.rs`。

## 规则

### 1. handler 返回 AppError，不返回 StatusCode

```rust
// ✅ 正确
async fn my_handler(...) -> Result<Json<...>, AppError> { ... }

// ❌ 错误
async fn my_handler(...) -> Result<Json<...>, StatusCode> { ... }
```

### 2. 用 `?` 传播错误，不用 `.map_err(|_| ...)`

```rust
// ✅ 正确：sqlx::Error 自动转为 AppError，打印详情
let rows = repo.do_something().await?;

// ❌ 错误：下划线丢弃了错误信息，500 时无法排查
let rows = repo.do_something().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
```

### 3. 业务错误用 AppError 的便捷方法

```rust
// 400
return Err(AppError::bad_request("群名不能为空"));

// 403
return Err(AppError::forbidden("非群主，无权操作"));

// 404
return Err(AppError::not_found("群聊不存在"));

// 500（带上下文）
return Err(AppError::internal(err, "add_members"));
```

### 4. SQL 中 COALESCE 的类型要匹配

```sql
-- ✅ 正确：显式标注类型
SELECT COALESCE(status, 0::SMALLINT) FROM conversations

-- ❌ 错误：0 是 INT4，status 是 SMALLINT，COALESCE 会提升为 INT4
SELECT COALESCE(status, 0) FROM conversations
```

sqlx 在运行时解码时会检查类型匹配，不匹配会报错。

### 5. 旧代码兼容

`AppError` 实现了 `From<StatusCode>`，旧代码的 `Err(StatusCode::BAD_REQUEST)` 不需要改，自动转换。新代码应该用 `AppError::bad_request(...)` 带上错误消息。
