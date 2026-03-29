# IM Core v0.0.2 — 服务端任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。
本版本实现会话管理（创建、列表、删除）+ 种子数据。

---

## 执行顺序

1. ✅ 任务 1 — 数据库迁移文件（无依赖）
2. ✅ 任务 2 — im-conversation crate 骨架 + 依赖（无依赖）
3. ✅ 任务 3 — models.rs 数据模型（依赖任务 2）
4. ✅ 任务 4 — repository.rs 数据库操作（依赖任务 3）
   - ✅ 4.1 find_private
   - ✅ 4.2 create_private
   - ✅ 4.3 list_by_user
   - ✅ 4.4 delete_for_user
5. ✅ 任务 5 — service.rs 业务逻辑（依赖任务 4）
6. ✅ 任务 6 — routes.rs HTTP 路由（依赖任务 5）
7. ✅ 任务 7 — lib.rs 导出 + 注册 workspace（依赖任务 6）
8. ✅ 任务 8 — main.rs 集成（依赖任务 7）
9. ✅ 任务 9 — 编译验证（依赖任务 8）
10. ✅ 任务 10 — 种子数据脚本（依赖任务 9，接口已就绪）
    - ✅ 10.1 seed-data.json 配置
    - ✅ 10.2 seed.ps1 脚本（通过 HTTP API 注册用户 + 创建会话）
11. ✅ 任务 11 — 种子数据验证

---

## 任务 1：数据库表定义 `✅`

文件：`server/migrations/20260329_002_conversations.sql`（新建）

### 1.1 创建 SQL 文件 `✅`

内容严格参考 design.md 中的表定义（conversations + conversation_members，不含 conversation_seq）。

### 1.2 更新 reset_db.ps1 `✅`

文件：`scripts/server/reset_db.ps1`（修改）

在现有的 auth 迁移之后，新增一行执行 conversations 迁移：

```powershell
$migrationFile2 = Join-Path $PSScriptRoot "..\..\server\migrations\20260329_002_conversations.sql"
& $psqlExe -U $PgUser -h 127.0.0.1 -p 5432 -w -d $DbName -f (Resolve-Path $migrationFile2).Path
```

---

## 任务 2：im-conversation crate 骨架 `✅`

文件：`server/modules/im-conversation/Cargo.toml`（新建）

### 2.1 Cargo.toml `✅`

```toml
[package]
name = "im-conversation"
version = "0.1.0"
edition = "2024"

[dependencies]
flash-core = { path = "../flash-core" }
axum.workspace = true
tokio.workspace = true
serde.workspace = true
serde_json.workspace = true
sqlx.workspace = true
chrono.workspace = true
uuid = { version = "1", features = ["v4"] }
```

### 2.2 workspace 注册 `✅`

`server/Cargo.toml` 的 workspace members 新增 `"modules/im-conversation"`。

---

## 任务 3：models.rs `✅`

文件：`server/modules/im-conversation/src/models.rs`（新建）

### 3.1 核心结构体 `✅`

```rust
// Conversation — 对应 conversations 表
// 字段：id(Uuid), conv_type(i16), name, avatar, owner_id, last_message_at,
//       last_message_preview, created_at, updated_at

// ConversationListItem — 会话列表查询结果（含对方信息和未读数）
// 字段：id, conv_type, name, avatar, owner_id, last_message_at, last_message_preview,
//       created_at, updated_at, unread_count, last_read_seq, peer_user_id, is_pinned, is_muted

// CreatePrivateRequest — POST /conversations 请求体
// 字段：peer_user_id(i64)

// ConversationResponse — 创建会话响应
// 字段：id, conv_type, peer_user_id, peer_nickname, peer_avatar, created_at
```

---

## 任务 4：repository.rs `✅`

文件：`server/modules/im-conversation/src/repository.rs`（新建）

### 4.1 find_private `✅`

```rust
/// 查询两人之间是否已有私聊会话
pub async fn find_private(&self, user_a: i64, user_b: i64) -> Result<Option<Conversation>>
// SQL: SELECT c.* FROM conversations c
//      JOIN conversation_members m1 ON m1.conversation_id = c.id AND m1.user_id = $1
//      JOIN conversation_members m2 ON m2.conversation_id = c.id AND m2.user_id = $2
//      WHERE c.type = 0
```

### 4.2 create_private `✅`

```rust
/// 创建私聊会话（事务：conversation + 两条 members）
pub async fn create_private(&self, user_a: i64, user_b: i64) -> Result<Conversation>
// 1. INSERT INTO conversations (type=0)
// 2. INSERT INTO conversation_members (conversation_id, user_a)
// 3. INSERT INTO conversation_members (conversation_id, user_b)
```

### 4.3 list_by_user `✅`

```rust
/// 查询用户的会话列表（含对方信息）
pub async fn list_by_user(&self, user_id: i64, limit: i64, offset: i64) -> Result<Vec<ConversationListItem>>
// SQL: SELECT c.*, cm.unread_count, cm.last_read_seq, cm.is_pinned, cm.is_muted,
//      peer.user_id as peer_user_id
//      FROM conversations c
//      JOIN conversation_members cm ON cm.conversation_id = c.id AND cm.user_id = $1
//      LEFT JOIN conversation_members peer ON peer.conversation_id = c.id
//               AND peer.user_id != $1 AND c.type = 0
//      WHERE cm.is_deleted = false
//      ORDER BY c.last_message_at DESC NULLS LAST
```

### 4.4 delete_for_user `✅`

```rust
/// 软删除会话（设置 is_deleted = true）
pub async fn delete_for_user(&self, conversation_id: Uuid, user_id: i64) -> Result<()>
// UPDATE conversation_members SET is_deleted = true
// WHERE conversation_id = $1 AND user_id = $2
```

---

## 任务 5：service.rs `✅`

文件：`server/modules/im-conversation/src/service.rs`（新建）

```rust
pub struct ConversationService { db: PgPool }

/// 创建私聊（幂等：已有则返回已有的）
pub async fn create_private(&self, user_id: i64, peer_user_id: i64) -> Result<...>
// 1. 校验 peer_user_id 存在（查 accounts 表）
// 2. repo.find_private(user_id, peer_user_id)
// 3. 已有 → 返回已有的（补充对方昵称头像）
// 4. 不存在 → repo.create_private → 返回新会话（补充对方昵称头像）

/// 获取会话列表（单聊补充对方昵称头像）
pub async fn get_list(&self, user_id: i64, limit: i64, offset: i64) -> Result<Vec<ConversationListItem>>
// 1. repo.list_by_user(user_id, limit, offset)
// 2. 批量查询 peer_user_id 对应的 user_profiles
// 3. 填充 name 和 avatar 字段

/// 删除会话
pub async fn delete_for_user(&self, conversation_id: Uuid, user_id: i64) -> Result<()>
// repo.delete_for_user
```

---

## 任务 6：routes.rs `✅`

文件：`server/modules/im-conversation/src/routes.rs`（新建）

```rust
// POST /conversations — 创建私聊
// GET /conversations?limit=20&offset=0 — 会话列表（分页）
// DELETE /conversations/:id — 删除会话
// 所有接口需要 Bearer Token（通过 flash_core::jwt::extract_user_id）
```

---

## 任务 7：lib.rs 导出 `✅`

文件：`server/modules/im-conversation/src/lib.rs`（新建）

```rust
pub mod models;
pub mod repository;
pub mod service;
mod routes;

pub use service::ConversationService;
pub fn router() -> Router<Arc<AppState>> { routes::router() }
```

---

## 任务 8：main.rs 集成 `✅`

文件：`server/src/main.rs`（修改）

### 8.1 添加依赖 `✅`

`server/Cargo.toml` 的 dependencies 新增 `im-conversation = { path = "modules/im-conversation" }`。

### 8.2 注册路由 `✅`

```rust
.merge(im_conversation::router())
```

---

## 任务 9：编译验证 `✅`

```powershell
cd server; cargo build
```

预期：整个 workspace 编译通过。

---

## 任务 10：种子数据脚本 `✅`

接口已就绪，通过 HTTP API 批量创建测试数据。

### 10.1 seed-data.json `✅`

文件：`scripts/database/im_seed/seed-data.json`（新建）

52 个中国传统色用户配置（系统助手 + 51 个传统色），包含 idx、phone_suffix、name、bio 字段。

### 10.2 seed.ps1 `✅`

文件：`scripts/database/im_seed/seed.ps1`（新建）

脚本逻辑：
1. 读取 seed-data.json
2. 遍历用户列表，对每个用户：
   - POST /auth/sms 发送验证码
   - POST /auth/login 登录（获取 token）
   - 如果是首次注册，POST /user/password 设置密码为 111111
3. 用朱红的 token，遍历其他 51 个用户：
   - POST /conversations { peer_user_id } 创建私聊会话
4. 打印创建结果统计

脚本需要服务已启动，数据库已重置。

---

## 任务 11：种子数据验证 `✅`

1. 重置数据库：`powershell -ExecutionPolicy Bypass -File scripts/server/reset_db.ps1`
2. 启动服务：`powershell -ExecutionPolicy Bypass -File scripts/server/start.ps1`
3. 执行种子脚本：`powershell -ExecutionPolicy Bypass -File scripts/database/im_seed/seed.ps1`
4. 用朱红登录，GET /conversations → 返回 51 条会话
5. POST /conversations { peer_user_id: 3 } → 返回已有会话（幂等）
6. DELETE /conversations/:id → 成功，再次 GET 列表少一条
