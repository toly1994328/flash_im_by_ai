# IM Friend v0.0.1 — 服务端任务清单

基于 [design.md](./design.md) 设计，列出需要创建/修改的具体细节。

全局约束：
- im-friend 是独立 crate，不依赖 im-conversation / im-message（通过 api 层 Option 注入）
- 错误处理用 thiserror 枚举（FriendError）
- 好友关系双向存储，所有写操作用事务
- 不实现好友备注、分组、黑名单、好友搜索、数量限制

---

## 执行顺序

1. ✅ 任务 1 — 数据库迁移（无依赖）
2. ✅ 任务 2 — proto 扩展（无依赖）
3. ✅ 任务 3 — im-friend crate 骨架 + Cargo.toml（依赖任务 1）
   - ✅ 3.1 Cargo.toml
   - ✅ 3.2 models.rs
   - ✅ 3.3 repository.rs
   - ✅ 3.4 service.rs
   - ✅ 3.5 api.rs
   - ✅ 3.6 lib.rs
4. ✅ 任务 4 — workspace 配置（依赖任务 3）
5. ✅ 任务 5 — im-ws dispatcher 扩展（依赖任务 2）
6. ✅ 任务 6 — flash-user 用户搜索接口（无依赖）
7. ✅ 任务 7 — main.rs 集成（依赖任务 3~6）
8. 🔧 任务 8 — 编译验证 + link-test-writer 测试脚本
9. ✅ 任务 9 — flash-user 用户资料接口 GET /api/users/:id（无依赖）

---

## 任务 1：数据库迁移 `✅ 已完成`

文件：`server/migrations/20260407_004_friends.sql`（新建）

### 1.1 创建 friend_requests 表 `⬜`

```sql
CREATE TABLE friend_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_user_id BIGINT NOT NULL,
    to_user_id BIGINT NOT NULL,
    message VARCHAR(200),
    status SMALLINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(from_user_id, to_user_id)
);

CREATE INDEX idx_friend_requests_to_user ON friend_requests(to_user_id, status);
CREATE INDEX idx_friend_requests_from_user ON friend_requests(from_user_id, status);
```

### 1.2 创建 friend_relations 表 `⬜`

```sql
CREATE TABLE friend_relations (
    user_id BIGINT NOT NULL,
    friend_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, friend_id)
);

CREATE INDEX idx_friend_relations_friend ON friend_relations(friend_id);
```

---

## 任务 2：proto 扩展 `✅ 已完成`

文件：`proto/ws.proto`（修改）

### 2.1 新增帧类型 `⬜`

在 WsFrameType 枚举中新增：

```protobuf
FRIEND_REQUEST = 7;
FRIEND_ACCEPTED = 8;
FRIEND_REMOVED = 9;
```

### 2.2 新增通知消息结构 `⬜`

在 ws.proto 末尾新增：

```protobuf
message FriendRequestNotification {
  string request_id = 1;
  string from_user_id = 2;
  string nickname = 3;
  string avatar = 4;
  string message = 5;
  int64 created_at = 6;
}

message FriendAcceptedNotification {
  string friend_id = 1;
  string nickname = 2;
  string avatar = 3;
  int64 created_at = 4;
}

message FriendRemovedNotification {
  string friend_id = 1;
}
```

proto 修改后 im-ws 的 build.rs 会在下次 cargo build 时自动重新生成 Rust 代码。

---

## 任务 3：im-friend crate `✅ 已完成`

### 3.1 Cargo.toml `⬜`

文件：`server/modules/im-friend/Cargo.toml`（新建）

```toml
[package]
name = "im-friend"
version = "0.1.0"
edition = "2024"

[dependencies]
flash-core = { path = "../flash-core" }
im-ws = { path = "../im-ws" }
im-conversation = { path = "../im-conversation" }
im-message = { path = "../im-message" }
axum.workspace = true
tokio.workspace = true
serde.workspace = true
serde_json.workspace = true
sqlx.workspace = true
chrono.workspace = true
uuid = { version = "1", features = ["v4"] }
thiserror = "2"
```

### 3.2 models.rs `⬜`

文件：`server/modules/im-friend/src/models.rs`（新建）

定义以下类型：

```rust
#[repr(i16)]
pub enum FriendRequestStatus { Pending=0, Accepted=1, Rejected=2 }

#[derive(FromRow, Serialize)]
pub struct FriendRequest {
    pub id: Uuid,
    pub from_user_id: i64,  // serde: id_as_string
    pub to_user_id: i64,    // serde: id_as_string
    pub message: Option<String>,
    pub status: i16,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(FromRow, Serialize)]
pub struct FriendRelation {
    pub user_id: i64,
    pub friend_id: i64,
    pub created_at: DateTime<Utc>,
}

#[derive(FromRow, Serialize)]
pub struct FriendWithProfile {
    pub friend_id: i64,     // serde: id_as_string
    pub nickname: String,
    pub avatar: Option<String>,
    pub bio: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Serialize)]
pub struct FriendRequestWithProfile {
    #[serde(flatten)]
    pub request: FriendRequest,
    pub nickname: String,
    pub avatar: Option<String>,
}

#[derive(Deserialize)]
pub struct SendFriendRequestRequest {
    pub to_user_id: i64,    // serde: id_as_string
    pub message: Option<String>,
}

#[derive(Deserialize)]
pub struct FriendListQuery {
    #[serde(default = "default_limit")]
    pub limit: i32,
    #[serde(default)]
    pub offset: i32,
}

#[derive(Error)]
pub enum FriendError {
    UserNotFound, RequestNotFound, RelationNotFound,
    AlreadyFriends, CannotAddSelf, Forbidden,
    Database(#[from] sqlx::Error),
}
```

注意：i64 字段需要用 `id_as_string` serde helper（从 flash-core 引入），确保 JSON 中序列化为字符串。

### 3.3 repository.rs `⬜`

文件：`server/modules/im-friend/src/repository.rs`（新建）

```rust
pub struct FriendRepository { pool: PgPool }
```

方法：

- `pub fn new(pool: PgPool) -> Self`
- `pub fn pool(&self) -> &PgPool`
- `pub async fn create_request(&self, from_user_id: i64, to_user_id: i64, message: Option<&str>) -> Result<FriendRequest, sqlx::Error>`
  1. INSERT INTO friend_requests ... ON CONFLICT(from_user_id, to_user_id) DO UPDATE SET message=$3, status=0, updated_at=NOW() RETURNING *
- `pub async fn find_request_by_id(&self, id: Uuid) -> Result<Option<FriendRequest>, sqlx::Error>`
- `pub async fn find_pending_request(&self, from_user_id: i64, to_user_id: i64) -> Result<Option<FriendRequest>, sqlx::Error>`
  1. WHERE from_user_id=$1 AND to_user_id=$2 AND status=0
- `pub async fn update_request_status(&self, id: Uuid, status: i16) -> Result<FriendRequest, sqlx::Error>`
  1. UPDATE ... SET status=$2, updated_at=NOW() ... RETURNING *
- `pub async fn get_received_requests(&self, user_id: i64, limit: i32, offset: i32) -> Result<Vec<FriendRequestWithProfile>, sqlx::Error>`
  1. JOIN user_profiles ON from_user_id，WHERE to_user_id=$1 AND status=0
- `pub async fn get_sent_requests(&self, user_id: i64, limit: i32, offset: i32) -> Result<Vec<FriendRequestWithProfile>, sqlx::Error>`
  1. JOIN user_profiles ON to_user_id
- `pub async fn create_relation(&self, user_id: i64, friend_id: i64) -> Result<FriendRelation, sqlx::Error>`
  1. 事务：INSERT 双向（A→B 和 B→A），ON CONFLICT DO NOTHING
- `pub async fn delete_relation(&self, user_id: i64, friend_id: i64) -> Result<(), sqlx::Error>`
  1. 事务：DELETE 双向
- `pub async fn get_friends(&self, user_id: i64, limit: i32, offset: i32) -> Result<Vec<FriendWithProfile>, sqlx::Error>`
  1. JOIN user_profiles ON friend_id
- `pub async fn is_friend(&self, user_id: i64, friend_id: i64) -> Result<bool, sqlx::Error>`
- `pub async fn user_exists(&self, user_id: i64) -> Result<bool, sqlx::Error>`
  1. SELECT id FROM accounts WHERE id=$1
- `pub async fn get_user_profile(&self, user_id: i64) -> Result<Option<(String, Option<String>)>, sqlx::Error>`
  1. SELECT nickname, avatar FROM user_profiles WHERE account_id=$1
- `pub async fn delete_request(&self, id: Uuid) -> Result<(), sqlx::Error>`
  1. DELETE FROM friend_requests WHERE id=$1

### 3.4 service.rs `⬜`

文件：`server/modules/im-friend/src/service.rs`（新建）

```rust
pub struct FriendService { repo: Arc<FriendRepository> }
```

方法：

- `pub fn new(repo: Arc<FriendRepository>) -> Self`
- `pub fn repo(&self) -> &FriendRepository`
- `pub async fn send_request(&self, from_user_id: i64, to_user_id: i64, message: Option<&str>) -> Result<FriendRequest, FriendError>`
  1. 校验 from != to → CannotAddSelf
  2. 校验 user_exists(to) → UserNotFound
  3. 校验 !is_friend → AlreadyFriends
  4. upsert_request（INSERT ... ON CONFLICT DO UPDATE，覆盖旧申请）
- `pub async fn accept_request(&self, request_id: Uuid, user_id: i64) -> Result<FriendRelation, FriendError>`
  1. find_request_by_id → RequestNotFound
  2. 校验 to_user_id == user_id → Forbidden
  3. 校验 status == Pending → Forbidden
  4. update_request_status(Accepted)
  5. create_relation
- `pub async fn reject_request(&self, request_id: Uuid, user_id: i64) -> Result<(), FriendError>`
  1. 同上校验
  2. update_request_status(Rejected)
- `pub async fn get_friends(&self, user_id: i64, limit: i32, offset: i32) -> Result<Vec<FriendWithProfile>, FriendError>`
- `pub async fn delete_friend(&self, user_id: i64, friend_id: i64) -> Result<(), FriendError>`
  1. 校验 is_friend → RelationNotFound
  2. delete_relation
- `pub async fn get_received_requests(&self, ...) -> Result<Vec<FriendRequestWithProfile>, FriendError>`
- `pub async fn get_sent_requests(&self, ...) -> Result<Vec<FriendRequestWithProfile>, FriendError>`
- `pub async fn delete_request(&self, request_id: Uuid, user_id: i64) -> Result<(), FriendError>`
  1. find_request_by_id → RequestNotFound
  2. 校验 from_user_id == user_id 或 to_user_id == user_id → Forbidden
  3. repo.delete_request(request_id)

### 3.5 api.rs `⬜`

文件：`server/modules/im-friend/src/api.rs`（新建）

API 状态结构体：

```rust
#[derive(Clone)]
pub struct FriendApiState {
    pub service: Arc<FriendService>,
    pub dispatcher: Option<Arc<MessageDispatcher>>,
    pub conv_service: Option<Arc<ConversationService>>,
    pub msg_service: Option<Arc<MessageService>>,
}
```

实现 `From<FriendError> for StatusCode`（或自定义 AppError 映射）。

路由处理函数（8 个）：

- `async fn send_request(State, Extension<CurrentUser>, Json<SendFriendRequestRequest>)`
  1. service.send_request()
  2. 查询申请者昵称/头像
  3. dispatcher.notify_friend_request() 推送给被申请者
  4. 返回 200 + 申请记录

- `async fn get_received_requests(State, Extension<CurrentUser>, Query<FriendListQuery>)`
- `async fn get_sent_requests(State, Extension<CurrentUser>, Query<FriendListQuery>)`

- `async fn accept_request(State, Extension<CurrentUser>, Path<Uuid>)`
  1. service.accept_request()
  2. conv_service.create_private(from, to) → 创建会话
  3. msg_service.send(打招呼消息) → 用申请留言或默认文本
  4. dispatcher.notify_friend_accepted() 推送给申请者
  5. 返回 200

- `async fn reject_request(State, Extension<CurrentUser>, Path<Uuid>)`
- `async fn get_friends(State, Extension<CurrentUser>, Query<FriendListQuery>)`

- `async fn delete_friend(State, Extension<CurrentUser>, Path<i64>)`
  1. service.delete_friend()
  2. dispatcher.notify_friend_removed() 推送给双方

- `async fn delete_request(State, Extension<CurrentUser>, Path<Uuid>)`
  1. 校验申请存在且当前用户是申请的发送方或接收方
  2. 删除申请记录
  3. 返回 200

路由注册：

```rust
pub fn friend_routes(state: FriendApiState) -> Router {
    Router::new()
        .route("/api/friends/requests", post(send_request))
        .route("/api/friends/requests/received", get(get_received_requests))
        .route("/api/friends/requests/sent", get(get_sent_requests))
        .route("/api/friends/requests/{id}/accept", post(accept_request))
        .route("/api/friends/requests/{id}/reject", post(reject_request))
        .route("/api/friends/requests/{id}", delete(delete_request))
        .route("/api/friends", get(get_friends))
        .route("/api/friends/{id}", delete(delete_friend))
        .with_state(state)
}
```

### 3.6 lib.rs `⬜`

文件：`server/modules/im-friend/src/lib.rs`（新建）

```rust
pub mod models;
pub mod repository;
pub mod service;
pub mod api;

pub use service::FriendService;
pub use repository::FriendRepository;
pub use api::{FriendApiState, friend_routes};
```

---

## 任务 4：workspace 配置 `✅ 已完成`

### 4.1 workspace members `⬜`

文件：`server/Cargo.toml`（修改）

在 `[workspace] members` 中新增：`"modules/im-friend"`

### 4.2 根 package 依赖 `⬜`

文件：`server/Cargo.toml`（修改）

在 `[dependencies]` 中新增：`im-friend = { path = "modules/im-friend" }`

---

## 任务 5：im-ws dispatcher 扩展 `✅ 已完成`

文件：`server/modules/im-ws/src/dispatcher.rs`（修改）

### 5.1 新增三个通知推送方法 `⬜`

在 MessageDispatcher impl 中新增：

```rust
/// 推送好友申请通知
pub async fn notify_friend_request(
    &self, to_user_id: i64, request_id: &str, from_user_id: i64,
    nickname: &str, avatar: Option<&str>, message: Option<&str>, created_at: i64,
)
```
1. 构造 FriendRequestNotification protobuf
2. 封装为 WsFrame(type=FRIEND_REQUEST)
3. ws_state.send_to_user(to_user_id, frame)

```rust
/// 推送好友接受通知
pub async fn notify_friend_accepted(
    &self, to_user_id: i64, friend_id: i64,
    nickname: &str, avatar: Option<&str>, created_at: i64,
)
```
1. 构造 FriendAcceptedNotification
2. 封装为 WsFrame(type=FRIEND_ACCEPTED)
3. ws_state.send_to_user(to_user_id, frame)

```rust
/// 推送好友删除通知
pub async fn notify_friend_removed(&self, to_user_id: i64, friend_id: i64)
```
1. 构造 FriendRemovedNotification
2. 封装为 WsFrame(type=FRIEND_REMOVED)
3. ws_state.send_to_user(to_user_id, frame)

需要新增 import：`use crate::proto::{FriendRequestNotification, FriendAcceptedNotification, FriendRemovedNotification};`

---

## 任务 6：flash-user 用户搜索接口 `✅ 已完成`

文件：`server/modules/flash-user/src/routes.rs`（修改）

### 6.1 新增搜索路由 `⬜`

新增 handler：

```rust
async fn search_users(
    State(state): State<Arc<AppState>>,
    Query(query): Query<SearchQuery>,
) -> Result<Json<serde_json::Value>, StatusCode>
```

SearchQuery：`{ keyword: String, limit: i32 (default 20) }`

SQL：
```sql
SELECT p.account_id, p.nickname, p.avatar
FROM user_profiles p
JOIN accounts a ON a.id = p.account_id
WHERE a.status = 0 AND p.nickname ILIKE $1
ORDER BY p.nickname
LIMIT $2
```

keyword 需要转义 `%` 和 `_`，拼接为 `%keyword%`。

路由注册：`.route("/api/users/search", get(search_users))`

---

## 任务 7：main.rs 集成 `✅ 已完成`

文件：`server/src/main.rs`（修改）

### 7.1 创建 FriendService 并注册路由 `⬜`

在 main 函数中新增：

```rust
use im_friend::{FriendRepository, FriendService, FriendApiState, friend_routes};

let friend_repo = Arc::new(FriendRepository::new(db.clone()));
let friend_service = Arc::new(FriendService::new(friend_repo));

let friend_state = FriendApiState {
    service: friend_service,
    dispatcher: Some(dispatcher.clone()),
    conv_service: Some(Arc::new(im_conversation::service::ConversationService::new(db.clone()))),
    msg_service: Some(msg_service.clone()),
};
```

在 Router 链中新增：`.merge(friend_routes(friend_state))`

注意：ConversationService 需要从 im-conversation 导出。如果当前没有导出，需要在 im-conversation/src/lib.rs 中添加 `pub use service::ConversationService;`。

---

## 任务 8：编译验证 + 测试脚本 `🔧 进行中`

### 8.1 编译验证 `⬜`

```bash
cd server
cargo build
```

### 8.2 数据库迁移 `⬜`

手动执行 SQL 迁移文件，创建 friend_requests 和 friend_relations 表。

### 8.3 link-test-writer 测试脚本 `⬜`

按 `.kiro/steering/link-test-writer.md` 规范，生成 Python 测试脚本。

脚本位置：`docs/features/im/friend/api/friend/request/friend.py`
文档输出：`docs/features/im/friend/api/friend/doc/`

前置依赖：两个测试用户（PHONE_A=13800010001, PHONE_B=13800010002），通过 SMS 登录获取 token。

#### 接口清单

| # | 接口 | 方法 | 说明 | 预期状态码 |
|---|------|------|------|-----------|
| 1 | /api/users/search?keyword=... | GET | 搜索用户 | 200 |
| 2 | /api/friends/requests | POST | 发送好友申请（附留言） | 200 |
| 3 | /api/friends/requests | POST | 重复申请（upsert 覆盖旧申请） | 200 |
| 4 | /api/friends/requests | POST | 不能加自己 | 400 |
| 5 | /api/friends/requests | POST | 目标用户不存在 | 404 |
| 6 | /api/friends/requests/received | GET | B 查询收到的申请 | 200 |
| 7 | /api/friends/requests/sent | GET | A 查询发送的申请 | 200 |
| 8 | /api/friends/requests/:id/accept | POST | B 接受申请 | 200 |
| 9 | /api/friends/requests/:id/accept | POST | 重复接受（非 pending） | 403 |
| 10 | /api/friends | GET | A 查询好友列表 | 200 |
| 11 | /api/friends | GET | B 查询好友列表 | 200 |
| 12 | /conversations | GET | 验证自动创建的私聊会话 | 200 |
| 13 | /api/friends/:id | DELETE | A 删除好友 B | 200 |
| 14 | /api/friends | GET | 删除后好友列表为空 | 200 |
| 15 | /api/friends/requests | POST | 重新发送申请（删除好友后） | 200 |
| 16 | /api/friends/requests/:id/reject | POST | B 拒绝申请 | 200 |
| 17 | /api/friends/requests/received | GET | 拒绝后无 pending 申请 | 200 |

#### 测试用例数据

```
pre: 登录用户 A 和 B，获取 token 和 user_id

step 1: GET /api/users/search?keyword={B的昵称前缀}
  预期: status=200, data 数组非空, 包含 B 的 user_id

step 2: POST /api/friends/requests — 发送好友申请
  请求体: {"to_user_id": "{uid_b}", "message": "你好，我是测试用户A"}
  预期: status=200, data.status=0, data.from_user_id=uid_a, data.to_user_id=uid_b
  断言: data.id 非空（UUID），data.message="你好，我是测试用户A"

step 3: POST /api/friends/requests — 重复申请（upsert 覆盖）
  请求体: {"to_user_id": "{uid_b}"}
  预期: status=200（upsert 覆盖旧申请，不再返回 400）

step 4: POST /api/friends/requests — 不能加自己
  请求体: {"to_user_id": "{uid_a}"}
  预期: status=400, body 包含 {"error": "..."}

step 5: POST /api/friends/requests — 目标用户不存在
  请求体: {"to_user_id": "999999"}
  预期: status=404, body 包含 {"error": "..."}

step 6: GET /api/friends/requests/received（B 的 token）
  预期: status=200, data 数组包含 step2 的申请, nickname 非空

step 7: GET /api/friends/requests/sent（A 的 token）
  预期: status=200, data 数组包含 step2 的申请

step 8: POST /api/friends/requests/{request_id}/accept（B 的 token）
  预期: status=200
  副作用: 双方成为好友，自动创建私聊会话

step 9: POST /api/friends/requests/{request_id}/accept（B 的 token，重复接受）
  预期: status=403（申请已非 pending）

step 10: GET /api/friends（A 的 token）
  预期: status=200, data 数组包含 B, friend_id=uid_b, nickname 非空

step 11: GET /api/friends（B 的 token）
  预期: status=200, data 数组包含 A

step 12: GET /conversations（A 的 token）
  预期: status=200, data 中存在与 B 的私聊会话

step 13: DELETE /api/friends/{uid_b}（A 的 token）
  预期: status=200

step 14: GET /api/friends（A 的 token）
  预期: status=200, data 数组不包含 B

step 15: POST /api/friends/requests — 删除好友后重新申请
  请求体: {"to_user_id": "{uid_b}", "message": "再次添加"}
  预期: status=200, data.status=0

step 16: POST /api/friends/requests/{new_request_id}/reject（B 的 token）
  预期: status=200

step 17: GET /api/friends/requests/received（B 的 token）
  预期: status=200, data 中无 pending 状态的申请（被拒绝的不显示）

step 18: DELETE /api/friends/requests/{request_id}（A 的 token）
  预期: status=200, 申请记录被删除

step 19: DELETE /api/friends/requests/{不存在的id}（A 的 token）
  预期: status=404, body 包含 {"error": "..."}
```

AI 执行时：按 link-test-writer 规范生成 `friend.py`，运行脚本验证全部 PASS，确认 `doc/` 下文档正确生成。


---

## 任务 9：flash-user 用户资料接口 `✅ 已完成`

文件：`server/modules/flash-user/src/handler.rs` + `routes.rs`（修改）

### 9.1 新增 get_user_public handler `✅`

```rust
async fn get_user_public(State, Path<i64>) -> Result<Json<Value>, StatusCode>
```

SQL：
```sql
SELECT p.account_id, p.nickname, p.avatar, p.signature
FROM user_profiles p
JOIN accounts a ON a.id = p.account_id
WHERE p.account_id = $1 AND a.status = 0
```

返回 `{ "data": { "id", "nickname", "avatar", "signature" } }`，用户不存在返回 404。

### 9.2 注册路由 `✅`

`.route("/api/users/{id}", get(get_user_public))`
