# iOS 合规 — 后端任务清单

基于 server/design.md 设计，列出需要创建/修改的具体细节。

**全局约束**：
- handler 返回 `Result<Json<...>, AppError>`，不返回 StatusCode
- 用 `?` 传播错误，不用 `.map_err(|_| ...)`
- 业务错误用 `AppError::bad_request/forbidden/not_found`
- SQL 放 handler 或 service，不用独立 repository 层（flash-user 模块现有风格）
- 迁移文件命名：`{日期}_{序号}_{描述}.sql`

---

## 执行顺序

1. ⬜ 任务 1 — 数据库迁移：创建 reports + user_blocks 表
2. ⬜ 任务 2 — flash-user: report_handler.rs 举报接口
3. ⬜ 任务 3 — flash-user: block_handler.rs 拉黑接口
4. ⬜ 任务 4 — flash-user: routes.rs 注册新路由
5. ⬜ 任务 5 — flash-auth: account_handler.rs 注销接口
6. ⬜ 任务 6 — flash-auth: routes.rs 注册注销路由
7. ⬜ 任务 7 — im-ws: dispatcher.rs 消息投递 block 检查
8. ⬜ 任务 8 — 编译验证 + 接口测试

---

## 任务 1：数据库迁移 `⬜ 待处理`

文件：`server/migrations/20260611_015_compliance.sql`（新建）

### 1.1 创建 reports 表 `⬜`

```sql
CREATE TABLE IF NOT EXISTS reports (
    id BIGSERIAL PRIMARY KEY,
    reporter_id BIGINT NOT NULL,
    target_type SMALLINT NOT NULL,
    target_id VARCHAR(64) NOT NULL,
    reason SMALLINT NOT NULL,
    description TEXT,
    status SMALLINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
```

### 1.2 创建 user_blocks 表 `⬜`

```sql
CREATE TABLE IF NOT EXISTS user_blocks (
    id BIGSERIAL PRIMARY KEY,
    blocker_id BIGINT NOT NULL,
    blocked_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id)
);
CREATE INDEX IF NOT EXISTS idx_blocks_blocker ON user_blocks(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocks_blocked ON user_blocks(blocked_id);
```

---

## 任务 2：report_handler.rs — 举报接口 `⬜ 待处理`

文件：`server/modules/flash-user/src/report_handler.rs`（新建）

### 2.1 请求结构体 `⬜`

```rust
#[derive(Deserialize)]
pub struct CreateReportRequest {
    pub target_type: i16,   // 0=消息, 1=用户
    pub target_id: String,
    pub reason: i16,        // 0~4
    pub description: Option<String>,
}
```

### 2.2 create_report handler `⬜`

签名：
```rust
pub async fn create_report(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<CreateReportRequest>,
) -> Result<(StatusCode, Json<MessageResponse>), AppError>
```

逻辑：
1. `extract_user_id(&headers)?`
2. 校验 target_type ∈ {0,1}，reason ∈ {0..4}
3. INSERT INTO reports
4. 返回 201 + "举报已提交"

---

## 任务 3：block_handler.rs — 拉黑接口 `⬜ 待处理`

文件：`server/modules/flash-user/src/block_handler.rs`（新建）

### 3.1 请求结构体 `⬜`

```rust
#[derive(Deserialize)]
pub struct BlockUserRequest {
    pub blocked_id: i64,
}
```

### 3.2 block_user handler `⬜`

签名：
```rust
pub async fn block_user(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<BlockUserRequest>,
) -> Result<(StatusCode, Json<MessageResponse>), AppError>
```

逻辑：
1. 提取 user_id
2. 不能拉黑自己
3. INSERT INTO user_blocks ON CONFLICT DO NOTHING
4. DELETE FROM friends WHERE (user_id, friend_id) 双向解除
5. 返回 201

### 3.3 unblock_user handler `⬜`

签名：
```rust
pub async fn unblock_user(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Path(blocked_id): Path<i64>,
) -> Result<Json<MessageResponse>, AppError>
```

逻辑：
1. DELETE FROM user_blocks WHERE blocker_id=me AND blocked_id=target
2. 返回 200

### 3.4 get_block_list handler `⬜`

签名：
```rust
pub async fn get_block_list(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
) -> Result<Json<serde_json::Value>, AppError>
```

逻辑：
1. SELECT b.blocked_id, p.nickname, p.avatar, b.created_at FROM user_blocks b JOIN user_profiles p ON p.account_id = b.blocked_id WHERE b.blocker_id = $1
2. 返回 `{ "data": [...] }`

### 3.5 check_block handler `⬜`

签名：
```rust
pub async fn check_block(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Query(q): Query<CheckBlockQuery>,
) -> Result<Json<serde_json::Value>, AppError>
```

逻辑：
1. SELECT 1 FROM user_blocks WHERE blocker_id=me AND blocked_id=q.user_id
2. 返回 `{ "is_blocked": true/false }`

---

## 任务 4：flash-user routes.rs 注册新路由 `⬜ 待处理`

文件：`server/modules/flash-user/src/routes.rs`（修改）

### 4.1 添加路由 `⬜`

```rust
.route("/api/reports", post(create_report))
.route("/api/blocks", get(get_block_list).post(block_user))
.route("/api/blocks/check", get(check_block))
.route("/api/blocks/{blocked_id}", delete(unblock_user))
```

### 4.2 更新 lib.rs 导出 `⬜`

文件：`server/modules/flash-user/src/lib.rs`

导出 `report_handler` 和 `block_handler` 模块。

---

## 任务 5：account_handler.rs — 注销接口 `⬜ 待处理`

文件：`server/modules/flash-auth/src/account_handler.rs`（新建）

### 5.1 请求结构体 `⬜`

```rust
#[derive(Deserialize)]
pub struct DeleteAccountRequest {
    pub password: String,
}
```

### 5.2 delete_account handler `⬜`

签名：
```rust
pub async fn delete_account(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(req): Json<DeleteAccountRequest>,
) -> Result<Json<MessageResponse>, AppError>
```

逻辑：
1. extract_user_id
2. 查 auth_credentials 获取 password hash
3. 如无密码 → AppError::bad_request("请先设置密码")
4. 验证密码（argon2）
5. 删除用户相关数据：DELETE FROM friends, conversations, messages 等
6. UPDATE accounts SET status = 2 WHERE id = $1
7. 返回 "注销成功"

---

## 任务 6：flash-auth routes.rs 注册路由 `⬜ 待处理`

文件：`server/modules/flash-auth/src/routes.rs`（修改）

### 6.1 添加路由 `⬜`

```rust
.route("/api/account/delete", post(delete_account))
```

### 6.2 更新 lib.rs 导出 `⬜`

导出 `account_handler` 模块。

---

## 任务 7：dispatcher.rs 消息投递 block 检查 `⬜ 待处理`

文件：`server/modules/im-ws/src/dispatcher.rs`（修改）

### 8.1 handle_chat_message 前加 block 检查 `⬜`

在 `handle_chat_message` 方法中，解析出 conversation_id 和 sender_id 后：

1. 查询会话类型：如果是私聊（conv_type=0），获取对方 user_id
2. SELECT 1 FROM user_blocks WHERE blocker_id = receiver_id AND blocked_id = sender_id
3. 如果存在 → 直接 return（静默丢弃，不回 ACK，不存库）
4. 不存在 → 继续正常流程

注意：只检查私聊，群聊不拦截。

---

## 任务 8：编译验证 + 接口测试 `⬜ 待处理`

### 9.1 cargo build `⬜`

```bash
cargo build
```

### 9.2 运行迁移 `⬜`

```bash
python scripts/server/reset_db.py  # 或手动执行 migration SQL
```

### 9.3 接口测试 `⬜`

```bash
# 举报
curl -X POST http://localhost:9600/api/reports \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"target_type":1,"target_id":"123","reason":2}'

# 拉黑
curl -X POST http://localhost:9600/api/blocks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"blocked_id":456}'

# 黑名单
curl http://localhost:9600/api/blocks -H "Authorization: Bearer $TOKEN"

# 取消拉黑
curl -X DELETE http://localhost:9600/api/blocks/456 -H "Authorization: Bearer $TOKEN"

# 注销
curl -X POST http://localhost:9600/api/account/delete \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"password":"test123"}'
```
