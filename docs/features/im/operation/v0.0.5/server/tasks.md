# 会话列表操作 — 服务端任务清单

基于 [design.md](design.md) 设计。改动涉及 im-conversation、im-message、im-ws、proto、flash-core 五个模块。

---

## 执行顺序

### 阶段一：数据与协议

1. ⬜ 任务 1 — 数据库迁移：`pinned_at` 列（无依赖）
2. ⬜ 任务 2 — Proto 扩展：`ConversationUpdate` 加 optional 字段（无依赖）

### 阶段二：基础设施

3. ⬜ 任务 3 — 依赖注入：`AppState` 挂 `broadcaster`，`im-conversation` 依赖 `im-message`（依赖无）
4. ⬜ 任务 4 — Broadcast trait 扩展：`broadcast_conversation_state_update`（依赖任务 2）
5. ⬜ 任务 5 — WsBroadcaster + NoopBroadcaster 实现（依赖任务 4）

### 阶段三：会话操作

6. ⬜ 任务 6 — Repository：`toggle_pin`、`toggle_mute`、`mark_unread` + 排序更新（依赖任务 1）
7. ⬜ 任务 7 — Models：`ToggleResponse` + `ConversationListItem` 补 `pinned_at`（依赖任务 1）
8. ⬜ 任务 8 — Service：3 个 toggle 方法 + delete WS 推送（依赖任务 3、5、6）
9. ⬜ 任务 9 — Routes：注册 3 个新端点 + 更新已有 handler 传参（依赖任务 3、7、8）

### 阶段四：验证

10. ⬜ 任务 10 — 编译验证 + 手动 curl 验证

---

## 任务 1：数据库迁移 `⬜ 待处理`

文件：`server/migrations/20260703_019_conversation_pinned_at.sql`（新建）

### 1.1 新建迁移文件 `⬜`

```sql
-- 新增 pinned_at 字段，用于置顶排序（线上无历史数据，无需回填）
ALTER TABLE conversation_members ADD COLUMN pinned_at TIMESTAMPTZ;

COMMENT ON COLUMN conversation_members.pinned_at IS '置顶时间，NULL 表示未置顶';
```

改动类型：新建文件，无依赖。

---

## 任务 2：Proto 扩展 `⬜ 待处理`

文件：`proto/message.proto`（修改）

### 2.1 扩展 `ConversationUpdate` 消息 `⬜`

在现有 `ConversationUpdate` 末尾追加 3 个 optional 字段：

```protobuf
message ConversationUpdate {
  string conversation_id = 1;
  string last_message_preview = 2;
  int64 last_message_at = 3;
  int32 unread_count = 4;
  int32 total_unread = 5;
  string last_message_extra = 6;
  // ↓ 新增
  optional bool is_pinned = 7;
  optional bool is_muted = 8;
  optional bool is_deleted = 9;
}
```

### 2.2 重新生成 proto 代码 `⬜`

```bash
cd proto && cargo build
```

改动类型：修改文件。

---

## 任务 3：依赖注入 `⬜ 待处理`

改动涉及 3 个文件：`AppState`、`im-conversation/Cargo.toml`、`main.rs`。

### 3.1 `AppState` 加 `broadcaster` 字段 `⬜`

文件：`server/modules/flash-core/src/state.rs`（修改）

```rust
use std::sync::Arc;
use im_message::MessageBroadcaster;  // 新增 import

pub struct AppState {
    pub db: PgPool,
    pub broadcaster: Arc<dyn MessageBroadcaster>,  // 新增
}
```

### 3.2 `create_app_state` 接收 broadcaster `⬜`

```rust
pub fn create_app_state(db: PgPool, broadcaster: Arc<dyn MessageBroadcaster>) -> Arc<AppState> {
    Arc::new(AppState { db, broadcaster })
}
```

### 3.3 `im-conversation/Cargo.toml` 加 `im-message` 依赖 `⬜`

文件：`server/modules/im-conversation/Cargo.toml`（修改）

```toml
[dependencies]
im-message = { path = "../im-message" }  # 新增，用于 MessageBroadcaster trait
```

### 3.4 更新 `main.rs` 调用处 `⬜`

文件：`server/src/main.rs`（修改）

找到 `create_app_state` 调用处，传入 `broadcaster`：

```rust
let broadcaster = Arc::new(WsBroadcaster::new(ws_state.clone(), db.clone()));
let state = create_app_state(db.clone(), broadcaster.clone());
```

改动类型：修改文件。

---

## 任务 4：Broadcast trait 扩展 `⬜ 待处理`

文件：`server/modules/im-message/src/broadcast.rs`（修改）

### 4.1 新增 `broadcast_conversation_state_update` 方法 `⬜`

在 `MessageBroadcaster` trait 中追加新方法：

```rust
/// 广播会话状态变更给指定用户的全部在线设备（pin/mute/unread/delete）
async fn broadcast_conversation_state_update(
    &self,
    user_id: i64,
    conversation_id: Uuid,
    is_pinned: Option<bool>,
    is_muted: Option<bool>,
    is_deleted: bool,
    unread_count: Option<i32>,
    total_unread: Option<i32>,
);
```

参数说明：
- `user_id`：操作者 ID（仅推给本人，用于多设备同步）
- `conversation_id`：目标会话
- `is_pinned` / `is_muted`：`Some(bool)` 表示 toggle 操作，`None` 表示本次不涉及
- `is_deleted`：`true` 表示删除会话
- `unread_count`：标记未读时传 `Some(1)`
- `total_unread`：标记未读时传最新汇总值

### 4.2 `NoopBroadcaster` 空实现 `⬜`

```rust
async fn broadcast_conversation_state_update(
    &self,
    _user_id: i64,
    _conversation_id: Uuid,
    _is_pinned: Option<bool>,
    _is_muted: Option<bool>,
    _is_deleted: bool,
    _unread_count: Option<i32>,
    _total_unread: Option<i32>,
) {}
```

改动类型：修改文件，依赖任务 2（proto 编译通过后 trait 引用新字段）。

---

## 任务 5：WsBroadcaster 实现 `⬜ 待处理`

文件：`server/modules/im-ws/src/broadcaster.rs`（修改）

### 5.1 实现 `broadcast_conversation_state_update` `⬜`

核心逻辑：用 `ConversationUpdate` proto 按需填充字段 → `send_to_user(user_id)`。

```rust
async fn broadcast_conversation_state_update(
    &self,
    user_id: i64,
    conversation_id: Uuid,
    is_pinned: Option<bool>,
    is_muted: Option<bool>,
    is_deleted: bool,
    unread_count: Option<i32>,
    total_unread: Option<i32>,
) {
    let mut update = ConversationUpdate {
        conversation_id: conversation_id.to_string(),
        // 消息相关字段全部用默认值（空串 / 0）
        last_message_preview: String::new(),
        last_message_at: 0,
        unread_count: unread_count.unwrap_or(0),
        total_unread: total_unread.unwrap_or(0),
        last_message_extra: String::new(),
        // 新增 optional 字段
        is_pinned,
        is_muted,
        is_deleted: if is_deleted { Some(true) } else { None },
    };

    let frame = WsFrame {
        r#type: WsFrameType::ConversationUpdate as i32,
        payload: update.encode_to_vec(),
    };
    self.ws_state.send_to_user(user_id, frame.encode_to_vec()).await;
}
```

要点：
- 只发给 `user_id` 一人（`send_to_user`，非 `send_to_users`）
- proto 已扩展 `is_pinned`/`is_muted`/`is_deleted`（任务 2）
- `is_deleted` 为 `true` 时设 `Some(true)`，否则 `None`（避免干扰正常消息推送）
- 确保 `ConversationUpdate` 的构建方式与 `broadcast_conversation_update` 原有逻辑一致

改动类型：修改文件，依赖任务 2 + 4。

---

## 任务 6：Repository 层 `⬜ 待处理`

文件：`server/modules/im-conversation/src/repository.rs`（修改）

### 6.1 `toggle_pin` — 翻转置顶状态 `⬜`

```rust
/// 翻转置顶状态，返回新状态。置顶时写入 pinned_at，取消时清空。
pub async fn toggle_pin(
    &self,
    conversation_id: Uuid,
    user_id: i64,
) -> Result<bool, sqlx::Error> {
    // 单条 SQL 原子翻转：is_pinned = NOT is_pinned，同步维护 pinned_at
    // UPDATE conversation_members
    //   SET is_pinned = NOT is_pinned,
    //       pinned_at = CASE WHEN is_pinned THEN NULL ELSE NOW() END
    // WHERE conversation_id=$1 AND user_id=$2
    // RETURNING is_pinned
}
```

### 6.2 `toggle_mute` — 翻转免打扰状态 `⬜`

```rust
/// 翻转免打扰状态，返回新状态
pub async fn toggle_mute(
    &self,
    conversation_id: Uuid,
    user_id: i64,
) -> Result<bool, sqlx::Error> {
    // UPDATE conversation_members SET is_muted = NOT is_muted WHERE ...
    // RETURNING is_muted
}
```

SQL：
```
UPDATE conversation_members SET is_muted = NOT is_muted
WHERE conversation_id=$1 AND user_id=$2
RETURNING is_muted
```

### 6.3 `mark_unread` — 标记未读 `⬜`

```rust
/// 将会话未读数设为 1
pub async fn mark_unread(
    &self,
    conversation_id: Uuid,
    user_id: i64,
) -> Result<(), sqlx::Error> {
    // UPDATE conversation_members SET unread_count = 1 WHERE ...
}
```

SQL：
```
UPDATE conversation_members SET unread_count = 1
WHERE conversation_id=$1 AND user_id=$2
```

### 6.4 `list_by_user` 排序更新 `⬜`

修改 `ORDER BY` 子句，置顶会话优先并按 `pinned_at` 排序：

```sql
-- 原：ORDER BY c.last_message_at DESC NULLS LAST, c.created_at DESC
-- 新：
ORDER BY cm.is_pinned DESC, cm.pinned_at DESC NULLS LAST, c.last_message_at DESC NULLS LAST, c.created_at DESC
```

同时在 SELECT 中补上 `cm.pinned_at` 列（配合任务 7 的 `ConversationListItem` 加字段）。

改动类型：修改文件，依赖任务 1（pinned_at 列已存在）。

---

## 任务 7：Models 层 `⬜ 待处理`

文件：`server/modules/im-conversation/src/models.rs`（修改）

### 7.1 新增 `ToggleResponse` 结构体 `⬜`

```rust
/// toggle 操作响应（pin/mute 共用）
#[derive(Debug, Serialize)]
pub struct ToggleResponse {
    pub is_pinned: Option<bool>,
    pub is_muted: Option<bool>,
    pub unread_count: Option<i32>,
}
```

三个字段均为 `Option`，调用方按需填充。pin 只填 `is_pinned`，mute 只填 `is_muted`，unread 只填 `unread_count`。

### 7.2 `ConversationListItem` 补 `pinned_at` 字段 `⬜`

```rust
#[derive(Debug, Clone, Serialize, FromRow)]
pub struct ConversationListItem {
    // ... 已有字段不变 ...
    pub is_pinned: bool,
    pub is_muted: bool,
    pub pinned_at: Option<DateTime<Utc>>,  // 新增
}
```

**为什么加在 `ConversationListItem` 而非 `ConversationListResponse`**：排序已由 SQL 处理，前端当前不需要 `pinned_at`。加在 `FromRow` 结构体上是因为 SQL 返回了该列，`FromRow` 必须有对应字段否则反序列化失败。

改动类型：修改文件，依赖任务 1。

---

## 任务 8：Service 层 `⬜ 待处理`

文件：`server/modules/im-conversation/src/service.rs`（修改）

### 8.1 构造函数接收 broadcaster `⬜`

```rust
use std::sync::Arc;
use im_message::MessageBroadcaster;

pub struct ConversationService {
    repo: ConversationRepository,
    db: PgPool,
    broadcaster: Arc<dyn MessageBroadcaster>,  // 新增
}

impl ConversationService {
    pub fn new(db: PgPool, broadcaster: Arc<dyn MessageBroadcaster>) -> Self {
        let repo = ConversationRepository::new(db.clone());
        Self { repo, db, broadcaster }
    }
}
```

### 8.2 `toggle_pin` 方法 `⬜`

```rust
pub async fn toggle_pin(
    &self,
    conversation_id: Uuid,
    user_id: i64,
) -> Result<ToggleResponse, StatusCode> {
    // 1. 校验会话是否存在 → 否 return 404
    // 2. 校验 is_member → 否 return 403
    // 3. repo.toggle_pin(conversation_id, user_id) → is_pinned
    // 3. broadcaster.broadcast_conversation_state_update(
    //        user_id, conversation_id,
    //        is_pinned=Some(is_pinned), is_muted=None,
    //        is_deleted=false, unread_count=None, total_unread=None
    //    )
    // 4. return ToggleResponse { is_pinned: Some(is_pinned), is_muted: None, unread_count: None }
}
```

### 8.3 `toggle_mute` 方法 `⬜`

```rust
pub async fn toggle_mute(
    &self,
    conversation_id: Uuid,
    user_id: i64,
) -> Result<ToggleResponse, StatusCode> {
    // 1. 校验会话是否存在 → 否 return 404
    // 2. 校验 is_member → 否 return 403
    // 3. repo.toggle_mute(conversation_id, user_id) → is_muted
    // 3. broadcaster.broadcast_conversation_state_update(
    //        user_id, conversation_id,
    //        is_pinned=None, is_muted=Some(is_muted),
    //        is_deleted=false, unread_count=None, total_unread=None
    //    )
    // 4. return ToggleResponse { is_pinned: None, is_muted: Some(is_muted), unread_count: None }
}
```

### 8.4 `mark_unread` 方法 `⬜`

```rust
pub async fn mark_unread(
    &self,
    conversation_id: Uuid,
    user_id: i64,
) -> Result<ToggleResponse, StatusCode> {
    // 1. 校验会话是否存在 → 否 return 404
    // 2. 校验 is_member → 否 return 403
    // 3. repo.mark_unread(conversation_id, user_id)
    // 3. 查询 total_unread: SELECT COALESCE(SUM(unread_count),0) FROM conversation_members WHERE user_id=$1 AND is_deleted=false
    // 4. broadcaster.broadcast_conversation_state_update(
    //        user_id, conversation_id,
    //        is_pinned=None, is_muted=None,
    //        is_deleted=false, unread_count=Some(1), total_unread=Some(total)
    //    )
    // 5. return ToggleResponse { is_pinned: None, is_muted: None, unread_count: Some(1) }
}
```

### 8.5 `delete_for_user` 补齐 WS 推送 `⬜`

在现有 `delete_for_user` 方法末尾（`Ok(())` 之前），追加 WS 推送：

```rust
// 现有代码:
//   let deleted = self.repo.delete_for_user(conversation_id, user_id).await?;
//   if !deleted { return Err(StatusCode::NOT_FOUND); }

// 新增: WS 推送 is_deleted
self.broadcaster.broadcast_conversation_state_update(
    user_id, conversation_id,
    None, None, true, None, None,
).await;
```

改动类型：修改文件，依赖任务 3（broadcaster 注入）、5（broadcaster 实现）、6（repo 方法）。

---

## 任务 9：Routes 层 `⬜ 待处理`

文件：`server/modules/im-conversation/src/routes.rs`（修改）

### 9.1 新增 3 个 handler `⬜`

```rust
use super::models::ToggleResponse;

/// POST /conversations/{id}/pin
async fn toggle_pin(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Path(id): Path<String>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    // 1. extract_user_id
    // 2. Uuid::parse_str → 失败返回 400
    // 3. ConversationService::new(state.db.clone(), state.broadcaster.clone())
    // 4. service.toggle_pin(conversation_id, user_id).await → Json
}

/// POST /conversations/{id}/mute
async fn toggle_mute(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Path(id): Path<String>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    // 同上结构，调 service.toggle_mute
}

/// POST /conversations/{id}/unread
async fn mark_unread(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Path(id): Path<String>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    // 同上结构，调 service.mark_unread
}
```

### 9.2 注册路由 `⬜`

```rust
pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/conversations", post(create_conversation).get(list_conversations))
        .route("/conversations/{id}", delete(delete_conversation).get(get_conversation))
        .route("/conversations/{id}/read", post(mark_read))
        .route("/conversations/{id}/pin", post(toggle_pin))     // 新增
        .route("/conversations/{id}/mute", post(toggle_mute))   // 新增
        .route("/conversations/{id}/unread", post(mark_unread)) // 新增
        .route("/api/conversations/search-joined-groups", get(search_joined_groups))
}
```

### 9.3 更新已有 handler 传参 `⬜`

所有已有 handler 中 `ConversationService::new(state.db.clone())` 改为 `ConversationService::new(state.db.clone(), state.broadcaster.clone())`。

涉及函数：`create_conversation`、`list_conversations`、`get_conversation`、`delete_conversation`、`mark_read`。

改动类型：修改文件，依赖任务 3 + 7 + 8。

---

## 任务 10：编译验证 `⬜ 待处理`

### 10.1 `cargo build` `⬜`

```bash
cd server && cargo build 2>&1
```

确认无编译错误。

### 10.2 `cargo check --tests` `⬜`

```bash
cd server && cargo check --tests 2>&1
```

确认测试代码也编译通过（如有 `NoopBroadcaster` 测试）。

### 10.3 手动 curl 验证 `⬜`

```bash
# 置顶（调用两次确认翻转）
curl -X POST http://localhost:3000/conversations/{id}/pin -H "Authorization: Bearer {token}"
curl -X POST http://localhost:3000/conversations/{id}/pin -H "Authorization: Bearer {token}"

# 免打扰
curl -X POST http://localhost:3000/conversations/{id}/mute -H "Authorization: Bearer {token}"

# 标记未读
curl -X POST http://localhost:3000/conversations/{id}/unread -H "Authorization: Bearer {token}"

# 边界：无效 UUID
curl -X POST http://localhost:3000/conversations/not-a-uuid/pin -H "Authorization: Bearer {token}"
# → 400

# 边界：非成员
curl -X POST http://localhost:3000/conversations/{other_user_conv_id}/pin -H "Authorization: Bearer {token}"
# → 403
```

---

## 全局约束

- **错误处理**：统一使用 `StatusCode` 返回（400/401/403/404/500），不自定义错误枚举
- **无 body 请求**：toggle 端点 `Content-Type` 不要求，请求体忽略
- **WS 推送范围**：仅 `send_to_user(操作者本人)`，用于多设备同步
- **排序一致性**：`list_by_user` 的 ORDER BY 变更需与 `ConversationListItem` 的 `pinned_at` 字段同步
