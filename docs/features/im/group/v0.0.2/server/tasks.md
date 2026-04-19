# 搜索加群与入群审批 — 服务端任务清单

基于 [design.md](design.md) 设计，列出需要创建/修改的具体细节。

全局约束：
- 所有新增接口放在 `im-group` crate 内（扩展 routes.rs / service.rs / repository.rs）
- `GroupApiState` 新增 `dispatcher: Arc<MessageDispatcher>` 字段（用于 WS 推送入群通知）
- 错误处理统一用 `StatusCode` 返回
- SQL 使用参数化查询
- 系统用户 id=0

---

## 执行顺序

1. ✅ 任务 1 — 数据库迁移（group_join_requests 表 + group_no 字段）
2. ✅ 任务 2 — Protobuf 定义（GROUP_JOIN_REQUEST 帧 + 通知消息）
3. ✅ 任务 3 — im-group/models.rs 扩展（新增请求/响应模型）
4. ✅ 任务 4 — im-group/repository.rs 扩展（搜索/入群/审批/查询）
5. ✅ 任务 5 — im-group/service.rs 扩展（业务逻辑 + 分支判断）
6. ✅ 任务 6 — im-ws/dispatcher.rs 扩展（notify_group_join_request）
7. ✅ 任务 7 — im-group/routes.rs 扩展（4 个新路由）
8. ✅ 任务 8 — main.rs 组装（注入 dispatcher）
9. ✅ 任务 9 — 编译验证 + 启动测试
10. ✅ 任务 10 — 群详情接口（GET /groups/{id}/detail）
11. ✅ 任务 11 — 群设置接口（PUT /groups/{id}/settings）

---

## 任务 1：数据库迁移 `⬜ 待处理`

文件：`server/migrations/20260419_006_group_join.sql`（新建）

### 1.1 group_no 序列和字段 `⬜`

给 group_info 表加群号字段，用自增序列从 10001 开始：

```sql
CREATE SEQUENCE IF NOT EXISTS group_no_seq START WITH 10001;
ALTER TABLE group_info ADD COLUMN IF NOT EXISTS group_no BIGINT UNIQUE DEFAULT nextval('group_no_seq');
```

### 1.2 group_join_requests 表 `⬜`

```sql
CREATE TABLE IF NOT EXISTS group_join_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL,
    user_id BIGINT NOT NULL,
    message VARCHAR(200),
    status SMALLINT NOT NULL DEFAULT 0,  -- 0=待处理 1=已同意 2=已拒绝
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_group_join_requests_conv ON group_join_requests(conversation_id, status);
CREATE INDEX idx_group_join_requests_user ON group_join_requests(user_id, status);
```

### 1.3 回填已有群的 group_no `⬜`

`ALTER TABLE ADD COLUMN ... DEFAULT nextval()` 对已有行不会自动填充序列值。需要手动回填：

```sql
UPDATE group_info SET group_no = nextval('group_no_seq') WHERE group_no IS NULL;
```

### 1.4 注册迁移脚本 `⬜`

在 `scripts/server/reset_db.py` 的 MIGRATIONS 列表中追加 `20260419_006_group_join.sql`。

### 1.5 验证 `⬜`

`python scripts/server/reset_db.py` 无报错。

---

## 任务 2：Protobuf 定义 `⬜ 待处理`

文件：`proto/ws.proto`（修改）

### 2.1 新增帧类型 `⬜`

```protobuf
enum WsFrameType {
  // ... 已有 0~9
  GROUP_JOIN_REQUEST = 10;
}
```

### 2.2 新增通知消息 `⬜`

```protobuf
message GroupJoinRequestNotification {
  string request_id = 1;
  string conversation_id = 2;
  string group_name = 3;
  string user_id = 4;
  string nickname = 5;
  string avatar = 6;
  string message = 7;
  int64 created_at = 8;
}
```

### 2.3 重新生成代码 `⬜`

`python scripts/proto/gen.py` 生成前后端 protobuf 代码。

---

## 任务 3：im-group/models.rs 扩展 `⬜ 待处理`

文件：`server/modules/im-group/src/models.rs`（修改）

### 3.1 入群申请请求 `⬜`

```rust
#[derive(Debug, Deserialize)]
pub struct JoinGroupRequest {
    pub message: Option<String>,
}
```

### 3.2 入群审批请求 `⬜`

```rust
#[derive(Debug, Deserialize)]
pub struct HandleJoinRequest {
    pub approved: bool,
}
```

### 3.3 群搜索结果 `⬜`

```rust
#[derive(Debug, Serialize, FromRow)]
pub struct GroupSearchResult {
    pub id: Uuid,
    pub name: Option<String>,
    pub avatar: Option<String>,
    pub owner_id: Option<i64>,
    pub group_no: i64,
    pub member_count: i64,
    pub is_member: bool,
    pub join_verification: bool,
    pub has_pending_request: bool,
}
```

### 3.4 入群申请列表项 `⬜`

```rust
#[derive(Debug, Serialize, FromRow)]
pub struct JoinRequestItem {
    pub id: Uuid,
    pub conversation_id: Uuid,
    pub group_name: Option<String>,
    pub group_avatar: Option<String>,
    pub user_id: i64,
    pub nickname: String,
    pub avatar: Option<String>,
    pub message: Option<String>,
    pub status: i16,
    pub created_at: DateTime<Utc>,
}
```

### 3.5 入群响应 `⬜`

```rust
#[derive(Debug, Serialize)]
pub struct JoinGroupResponse {
    pub auto_approved: bool,
}
```

### 3.6 搜索查询参数 `⬜`

```rust
#[derive(Debug, Deserialize)]
pub struct SearchQuery {
    pub keyword: Option<String>,
}
```

---

## 任务 4：im-group/repository.rs 扩展 `⬜ 待处理`

文件：`server/modules/im-group/src/repository.rs`（修改）

### 4.1 search_groups `⬜`

按群名 ILIKE 或群号精确匹配搜索。service 层判断 keyword 是否为纯数字，传入不同参数。

```rust
pub async fn search_groups(
    &self,
    user_id: i64,
    keyword: &str,
    is_numeric: bool,
) -> Result<Vec<GroupSearchResult>, sqlx::Error>
```

逻辑步骤：
1. 如果 is_numeric=true，WHERE 条件为 `gi.group_no = keyword::BIGINT`
2. 如果 is_numeric=false，WHERE 条件为 `c.name ILIKE '%' || keyword || '%'`（注意转义 keyword 中的 `%` 和 `_` 字符）
3. 子查询关联 member_count、is_member、join_verification、has_pending_request
4. LIMIT 20

### 4.2 join_group_direct `⬜`

无需验证时直接加入群聊：

```rust
pub async fn join_group_direct(
    &self,
    conversation_id: Uuid,
    user_id: i64,
) -> Result<(), sqlx::Error>
```

逻辑步骤：
1. INSERT conversation_members（ON CONFLICT 恢复 is_deleted）
2. 调用 `self.build_grid_avatar(conversation_id)` 刷新头像

### 4.3 create_join_request `⬜`

需要验证时创建入群申请：

```rust
pub async fn create_join_request(
    &self,
    conversation_id: Uuid,
    user_id: i64,
    message: Option<&str>,
) -> Result<Uuid, sqlx::Error>
```

返回新创建的 request id。

### 4.4 find_pending_request `⬜`

查询用户对某群是否有待处理申请：

```rust
pub async fn find_pending_request(
    &self,
    conversation_id: Uuid,
    user_id: i64,
) -> Result<Option<Uuid>, sqlx::Error>
```

SQL: `SELECT id FROM group_join_requests WHERE conversation_id=$1 AND user_id=$2 AND status=0`

### 4.5 get_join_request `⬜`

根据 request_id 查询申请详情：

```rust
pub async fn get_join_request(
    &self,
    request_id: Uuid,
) -> Result<Option<(Uuid, i64, i16)>, sqlx::Error>
```

返回 (conversation_id, user_id, status)。

### 4.6 update_join_request_status `⬜`

```rust
pub async fn update_join_request_status(
    &self,
    request_id: Uuid,
    status: i16,
) -> Result<(), sqlx::Error>
```

SQL: `UPDATE group_join_requests SET status=$2, updated_at=NOW() WHERE id=$1`

### 4.7 get_group_owner `⬜`

查询群主 ID：

```rust
pub async fn get_group_owner(
    &self,
    conversation_id: Uuid,
) -> Result<Option<i64>, sqlx::Error>
```

SQL: `SELECT owner_id FROM conversations WHERE id=$1 AND type=1`

### 4.8 get_join_verification `⬜`

查询群的入群验证开关：

```rust
pub async fn get_join_verification(
    &self,
    conversation_id: Uuid,
) -> Result<bool, sqlx::Error>
```

SQL: `SELECT COALESCE(join_verification, false) FROM group_info WHERE conversation_id=$1`

### 4.9 is_member `⬜`

检查用户是否是群成员：

```rust
pub async fn is_member(
    &self,
    conversation_id: Uuid,
    user_id: i64,
) -> Result<bool, sqlx::Error>
```

SQL: `SELECT EXISTS(SELECT 1 FROM conversation_members WHERE conversation_id=$1 AND user_id=$2 AND is_deleted=false)`

### 4.10 list_join_requests `⬜`

查询当前用户作为群主的所有入群申请：

```rust
pub async fn list_join_requests(
    &self,
    owner_id: i64,
) -> Result<Vec<JoinRequestItem>, sqlx::Error>
```

逻辑步骤：
1. JOIN conversations ON owner_id = $1 AND type = 1
2. JOIN group_join_requests ON conversation_id
3. JOIN user_profiles ON user_id（获取申请者昵称/头像）
4. ORDER BY created_at DESC

---

## 任务 5：im-group/service.rs 扩展 `⬜ 待处理`

文件：`server/modules/im-group/src/service.rs`（修改）

### 5.1 search_groups `⬜`

```rust
pub async fn search_groups(
    &self,
    user_id: i64,
    keyword: &str,
) -> Result<Vec<GroupSearchResult>, StatusCode>
```

逻辑步骤：
1. keyword.trim()，为空返回空 Vec
2. 判断 keyword 是否为纯数字（`keyword.parse::<i64>().is_ok()`）
3. 调用 repo.search_groups(user_id, keyword, is_numeric)

### 5.2 join_group `⬜`

```rust
pub enum JoinResult {
    AutoApproved,
    PendingApproval { request_id: Uuid, owner_id: i64 },
}

pub async fn join_group(
    &self,
    user_id: i64,
    conversation_id: Uuid,
    message: Option<&str>,
) -> Result<JoinResult, StatusCode>
```

逻辑步骤：
1. 校验群存在（get_group_owner 返回 Some）→ 404
2. 校验非成员（is_member = false）→ 400 "已经是群成员"
3. 校验无待处理申请（find_pending_request = None）→ 400 "已有待处理的入群申请"
4. 查 join_verification
5. 如果 false → repo.join_group_direct → 返回 AutoApproved
6. 如果 true → repo.create_join_request → 返回 PendingApproval { request_id, owner_id }

### 5.3 handle_join_request `⬜`

```rust
pub async fn handle_join_request(
    &self,
    owner_id: i64,
    conversation_id: Uuid,
    request_id: Uuid,
    approved: bool,
) -> Result<Option<i64>, StatusCode>
```

返回值：如果同意，返回 Some(申请者 user_id)（用于发系统消息）；拒绝返回 None。

逻辑步骤：
1. 校验当前用户是群主（get_group_owner == owner_id）→ 403
2. 校验申请存在且 status=0（get_join_request）→ 400 "该申请已处理" / 404
3. 如果 approved=true：
   - update_join_request_status(request_id, 1)
   - join_group_direct(conversation_id, applicant_user_id)
   - 返回 Some(applicant_user_id)
4. 如果 approved=false：
   - update_join_request_status(request_id, 2)
   - 返回 None

### 5.4 list_join_requests `⬜`

```rust
pub async fn list_join_requests(
    &self,
    owner_id: i64,
) -> Result<Vec<JoinRequestItem>, StatusCode>
```

直接调用 repo.list_join_requests(owner_id)。

---

## 任务 6：im-ws/dispatcher.rs 扩展 `⬜ 待处理`

文件：`server/modules/im-ws/src/dispatcher.rs`（修改）

### 6.1 新增 notify_group_join_request 方法 `⬜`

```rust
pub async fn notify_group_join_request(
    &self,
    to_user_id: i64,
    request_id: &str,
    conversation_id: &str,
    group_name: &str,
    user_id: i64,
    nickname: &str,
    avatar: Option<&str>,
    message: Option<&str>,
    created_at: i64,
)
```

逻辑步骤：
1. 构造 GroupJoinRequestNotification protobuf 消息
2. 包装为 WsFrame（type = GROUP_JOIN_REQUEST）
3. `self.ws_state.send_to_user(to_user_id, frame.encode_to_vec()).await`

### 6.2 import 新增 `⬜`

```rust
use crate::proto::GroupJoinRequestNotification;
```

---

## 任务 7：im-group/routes.rs 扩展 `⬜ 待处理`

文件：`server/modules/im-group/src/routes.rs`（修改）

### 7.1 GroupApiState 扩展 `⬜`

```rust
use im_ws::MessageDispatcher;

#[derive(Clone)]
pub struct GroupApiState {
    pub service: Arc<GroupService>,
    pub msg_service: Arc<MessageService>,
    pub dispatcher: Arc<MessageDispatcher>,  // 新增
}
```

### 7.2 search_groups handler `⬜`

```rust
/// GET /groups/search?keyword=xxx
async fn search_groups(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Query(query): Query<SearchQuery>,
) -> Result<Json<Vec<GroupSearchResult>>, StatusCode>
```

逻辑：提取 user_id → 调 service.search_groups → 返回 JSON 数组。

### 7.3 join_group handler `⬜`

```rust
/// POST /groups/{id}/join
async fn join_group(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Path(conv_id): Path<Uuid>,
    Json(req): Json<JoinGroupRequest>,
) -> Result<Json<JoinGroupResponse>, StatusCode>
```

逻辑步骤：
1. 提取 user_id
2. 调 service.join_group
3. 如果 AutoApproved → 发系统消息"XXX 加入了群聊" + 返回 {auto_approved: true}
4. 如果 PendingApproval → 先返回 {auto_approved: false}，然后 tokio::spawn 异步查申请者信息 + 调 dispatcher.notify_group_join_request 推送群主（不阻塞响应）

### 7.4 handle_join_request handler `⬜`

```rust
/// POST /groups/{id}/join-requests/{rid}/handle
async fn handle_join_request(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
    Path((conv_id, request_id)): Path<(Uuid, Uuid)>,
    Json(req): Json<HandleJoinRequest>,
) -> Result<Json<serde_json::Value>, StatusCode>
```

逻辑步骤：
1. 提取 user_id（群主）
2. 调 service.handle_join_request
3. 如果同意（返回 Some(applicant_id)）→ 查申请者昵称 → 发系统消息"XXX 加入了群聊"
4. 返回 {success: true}

### 7.5 list_join_requests handler `⬜`

```rust
/// GET /groups/join-requests
async fn list_join_requests(
    State(state): State<GroupApiState>,
    headers: HeaderMap,
) -> Result<Json<Vec<JoinRequestItem>>, StatusCode>
```

逻辑：提取 user_id → 调 service.list_join_requests → 返回 JSON 数组。

### 7.6 路由注册 `⬜`

```rust
pub fn group_routes(state: GroupApiState) -> Router {
    Router::new()
        .route("/groups", post(create_group))
        .route("/groups/search", get(search_groups))
        .route("/groups/{id}/join", post(join_group))
        .route("/groups/{id}/join-requests/{rid}/handle", post(handle_join_request))
        .route("/groups/join-requests", get(list_join_requests))
        .with_state(state)
}
```

---

## 任务 8：main.rs 组装 `⬜ 待处理`

文件：`server/src/main.rs`（修改）

### 8.1 GroupApiState 注入 dispatcher `⬜`

```rust
let group_api_state = GroupApiState {
    service: Arc::new(group_service),
    msg_service: msg_service.clone(),
    dispatcher: dispatcher.clone(),  // 新增
};
```

### 8.2 im-group Cargo.toml 新增依赖 `⬜`

`im-group` 的 Cargo.toml 需要新增对 `im-ws` 的依赖（用于引用 `MessageDispatcher` 类型）：

```toml
[dependencies]
im-ws = { path = "../im-ws" }
```

---

## 任务 9：编译验证 + 启动测试 `⬜ 待处理`

### 9.1 数据库迁移 `⬜`

```bash
python scripts/server/reset_db.py
```

### 9.2 Protobuf 生成 `⬜`

```bash
python scripts/proto/gen.py
```

### 9.3 编译 `⬜`

```bash
cargo build
```

### 9.4 启动服务 `⬜`

```bash
python scripts/server/start.py
```

### 9.5 接口测试 `⬜`

手动验证或编写测试脚本覆盖：
- GET /groups/search?keyword=爬山 → 返回结果含 group_no/member_count/is_member 等
- GET /groups/search?keyword=10001 → 按群号精确匹配
- POST /groups/{id}/join（无需验证）→ auto_approved=true
- POST /groups/{id}/join（需验证）→ auto_approved=false + 群主收到 WS 帧
- POST /groups/{id}/join（重复申请）→ 400
- POST /groups/{id}/join-requests/{rid}/handle {approved:true} → 成功 + 系统消息
- POST /groups/{id}/join-requests/{rid}/handle {approved:false} → 成功
- GET /groups/join-requests → 返回申请列表

---

## 任务 10：群详情接口 `⬜ 待处理`

文件：`server/modules/im-group/src/` 各层扩展

### 10.1 models.rs 新增 GroupDetail / GroupMember `⬜`

```rust
#[derive(Debug, Serialize)]
pub struct GroupDetail {
    pub id: Uuid,
    pub name: Option<String>,
    pub avatar: Option<String>,
    pub owner_id: Option<i64>,
    pub group_no: i64,
    pub member_count: i64,
    pub join_verification: bool,
    pub members: Vec<GroupMember>,
}

#[derive(Debug, Serialize, FromRow)]
pub struct GroupMember {
    pub user_id: i64,
    pub nickname: String,
    pub avatar: Option<String>,
}
```

### 10.2 repository.rs 新增 get_group_detail / get_group_members `⬜`

```rust
pub async fn get_group_detail(&self, conversation_id: Uuid) -> Result<Option<(...)>, sqlx::Error>
// SELECT c.*, gi.group_no, gi.join_verification, member_count

pub async fn get_group_members(&self, conversation_id: Uuid) -> Result<Vec<GroupMember>, sqlx::Error>
// SELECT cm.user_id, up.nickname, up.avatar FROM conversation_members cm JOIN user_profiles up ... WHERE is_deleted=false ORDER BY joined_at
```

### 10.3 service.rs 新增 get_group_detail `⬜`

校验当前用户是群成员 → 查群信息 + 成员列表 → 组装 GroupDetail 返回。

### 10.4 routes.rs 新增 get_group_detail handler `⬜`

```rust
/// GET /groups/{id}/detail
async fn get_group_detail(State, headers, Path(conv_id)) -> Result<Json<GroupDetail>, StatusCode>
```

### 10.5 路由注册 `⬜`

`.route("/groups/{id}/detail", get(get_group_detail))`

---

## 任务 11：群设置接口 `⬜ 待处理`

文件：`server/modules/im-group/src/` 各层扩展

### 11.1 models.rs 新增 UpdateGroupSettingsRequest `⬜`

```rust
#[derive(Debug, Deserialize)]
pub struct UpdateGroupSettingsRequest {
    pub join_verification: Option<bool>,
}
```

### 11.2 repository.rs 新增 update_group_settings `⬜`

```rust
pub async fn update_group_settings(&self, conversation_id: Uuid, join_verification: bool) -> Result<(), sqlx::Error>
// UPDATE group_info SET join_verification=$2, updated_at=NOW() WHERE conversation_id=$1
```

### 11.3 service.rs 新增 update_group_settings `⬜`

校验当前用户是群主 → 调 repo.update_group_settings。

### 11.4 routes.rs 新增 update_group_settings handler `⬜`

```rust
/// PUT /groups/{id}/settings
async fn update_group_settings(State, headers, Path(conv_id), Json(req)) -> Result<Json<Value>, StatusCode>
```

### 11.5 路由注册 `⬜`

`.route("/groups/{id}/settings", put(update_group_settings))`
