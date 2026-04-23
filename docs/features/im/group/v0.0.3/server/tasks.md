# 群成员管理与群详情 — 服务端任务清单

基于 [design.md](design.md) 设计，列出需要创建/修改的具体细节。

全局约束：
- 所有新增接口继续放在 `im-group` crate 内
- 权限校验在 service 层，每个方法开头先查 owner_id
- 系统消息在 routes 层发送（和 v0.0.1/v0.0.2 一致）
- 踢人和退群复用同一个 repository 方法 `remove_member`
- 解散先发系统消息再改 status
- 系统用户 id=0
- 新增 handler 返回 `Result<..., AppError>`，不返回 `StatusCode`
- 改名/改公告时发系统消息 + GROUP_INFO_UPDATE 推送

---

## 执行顺序

1. ✅ 任务 1 — 数据库迁移（conversations.status + group_info.announcement）
2. ✅ 任务 2 — models.rs 扩展（4 个新请求模型 + GroupDetail 扩展）
3. ✅ 任务 3 — repository.rs 扩展（9 个新方法）
4. ✅ 任务 4 — service.rs 扩展（7 个新方法，每个带权限校验）
5. ✅ 任务 5 — routes.rs 扩展（7 个新路由 handler + 系统消息 + GROUP_INFO_UPDATE 推送）
6. ✅ 任务 6 — MessageService.send 拦截已解散群
7. ✅ 任务 7 — GroupDetail 扩展（返回 status + announcement）
8. ✅ 任务 8 — 编译验证 + 接口测试
9. ✅ 任务 9 — AppError 统一错误处理
10. ✅ 任务 10 — GROUP_INFO_UPDATE WS 帧

---

## 任务 1：数据库迁移 `✅ 已完成`

文件：`server/migrations/20260420_007_group_manage.sql`（新建）

### 1.1 conversations 加 status 字段 `✅`

```sql
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS status SMALLINT NOT NULL DEFAULT 0;
-- 0=正常, 1=已解散
```

### 1.2 group_info 加 announcement 相关字段 `✅`

```sql
ALTER TABLE group_info ADD COLUMN IF NOT EXISTS announcement TEXT;
ALTER TABLE group_info ADD COLUMN IF NOT EXISTS announcement_updated_at TIMESTAMPTZ;
ALTER TABLE group_info ADD COLUMN IF NOT EXISTS announcement_updated_by BIGINT;
```

### 1.3 注册迁移脚本 `✅`

在 `scripts/server/reset_db.py` 的 MIGRATIONS 列表中追加。

### 1.4 验证 `✅`

`python scripts/server/reset_db.py` 无报错。

---

## 任务 2：models.rs 扩展 `✅ 已完成`

文件：`server/modules/im-group/src/models.rs`（修改）

### 2.1 新增请求模型 `✅`

```rust
#[derive(Debug, Deserialize)]
pub struct AddMembersRequest {
    pub member_ids: Vec<i64>,
}

#[derive(Debug, Deserialize)]
pub struct TransferOwnerRequest {
    pub new_owner_id: i64,
}

#[derive(Debug, Deserialize)]
pub struct UpdateGroupRequest {
    pub name: Option<String>,
    pub avatar: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateAnnouncementRequest {
    pub announcement: String,
}
```

### 2.2 GroupDetail 扩展 `✅`

给 `GroupDetail` 加 `status`、`announcement`、`announcement_updated_at` 字段：

```rust
pub struct GroupDetail {
    // ... 已有字段
    pub status: i16,
    pub announcement: Option<String>,
    pub announcement_updated_at: Option<DateTime<Utc>>,
}
```

---

## 任务 3：repository.rs 扩展 `✅ 已完成`

文件：`server/modules/im-group/src/repository.rs`（修改）

### 3.1 add_members `✅`

```rust
pub async fn add_members(&self, conversation_id: Uuid, member_ids: &[i64]) -> Result<usize, sqlx::Error>
```

逻辑：循环 INSERT conversation_members（ON CONFLICT 恢复 is_deleted）+ build_grid_avatar。返回实际新增数量。

### 3.2 remove_member `✅`

```rust
pub async fn remove_member(&self, conversation_id: Uuid, user_id: i64) -> Result<(), sqlx::Error>
```

逻辑：UPDATE is_deleted=true + build_grid_avatar。踢人和退群共用。

### 3.3 transfer_owner `✅`

```rust
pub async fn transfer_owner(&self, conversation_id: Uuid, new_owner_id: i64) -> Result<(), sqlx::Error>
```

SQL：`UPDATE conversations SET owner_id = $2 WHERE id = $1`

### 3.4 disband `✅`

```rust
pub async fn disband(&self, conversation_id: Uuid) -> Result<(), sqlx::Error>
```

SQL：`UPDATE conversations SET status = 1 WHERE id = $1`

### 3.5 update_announcement `✅`

```rust
pub async fn update_announcement(&self, conversation_id: Uuid, announcement: &str, updated_by: i64) -> Result<(), sqlx::Error>
```

SQL：`UPDATE group_info SET announcement = $2, announcement_updated_at = NOW(), announcement_updated_by = $3 WHERE conversation_id = $1`

### 3.6 update_group `✅`

```rust
pub async fn update_group(&self, conversation_id: Uuid, name: Option<&str>, avatar: Option<&str>) -> Result<(), sqlx::Error>
```

动态拼接 SQL，只更新传入的字段。

### 3.7 get_member_count `✅`

```rust
pub async fn get_member_count(&self, conversation_id: Uuid) -> Result<i64, sqlx::Error>
```

SQL：`SELECT COUNT(*) FROM conversation_members WHERE conversation_id = $1 AND is_deleted = false`

用于邀请入群时校验是否超过 max_members。

### 3.8 get_conversation_status `✅`

```rust
pub async fn get_conversation_status(&self, conversation_id: Uuid) -> Result<i16, sqlx::Error>
```

SQL：`SELECT COALESCE(status, 0::SMALLINT) FROM conversations WHERE id = $1`

注意：COALESCE 的默认值必须显式标注 `0::SMALLINT`，否则 sqlx 运行时解码会因 INT4 vs SMALLINT 类型不匹配报错。

### 3.9 get_member_ids `✅`

```rust
pub async fn get_member_ids(&self, conversation_id: Uuid) -> Result<Vec<i64>, sqlx::Error>
```

SQL：`SELECT user_id FROM conversation_members WHERE conversation_id = $1 AND is_deleted = false`

用于 GROUP_INFO_UPDATE 推送时获取所有活跃成员 ID。

---

## 任务 4：service.rs 扩展 `✅ 已完成`

文件：`server/modules/im-group/src/service.rs`（修改）

### 4.1 add_members `✅`

```rust
pub async fn add_members(&self, user_id: i64, conversation_id: Uuid, member_ids: &[i64]) -> Result<usize, StatusCode>
```

逻辑：
1. 校验当前用户是群成员（is_member）
2. 校验群未解散（get_conversation_status == 0）
3. 校验不超过 max_members
4. 调 repo.add_members
5. 返回新增数量

### 4.2 remove_member `✅`

```rust
pub async fn remove_member(&self, user_id: i64, conversation_id: Uuid, target_id: i64) -> Result<(), StatusCode>
```

逻辑：
1. 校验当前用户是群主
2. 校验 target_id != owner_id（不能踢自己）
3. 校验 target 是群成员
4. 调 repo.remove_member

### 4.3 leave `✅`

```rust
pub async fn leave(&self, user_id: i64, conversation_id: Uuid) -> Result<(), StatusCode>
```

逻辑：
1. 校验当前用户是群成员
2. 校验当前用户不是群主（群主不能退出）
3. 调 repo.remove_member

### 4.4 transfer_owner `✅`

```rust
pub async fn transfer_owner(&self, user_id: i64, conversation_id: Uuid, new_owner_id: i64) -> Result<(), StatusCode>
```

逻辑：
1. 校验当前用户是群主
2. 校验 new_owner_id 是群成员
3. 调 repo.transfer_owner

### 4.5 disband `✅`

```rust
pub async fn disband(&self, user_id: i64, conversation_id: Uuid) -> Result<(), StatusCode>
```

逻辑：
1. 校验当前用户是群主
2. 调 repo.disband（UPDATE status=1）

注意：系统消息在 routes 层发送，在 disband 之前。

### 4.6 update_announcement `✅`

```rust
pub async fn update_announcement(&self, user_id: i64, conversation_id: Uuid, announcement: &str) -> Result<(), StatusCode>
```

逻辑：
1. 校验当前用户是群主
2. 调 repo.update_announcement

### 4.7 update_group `✅`

```rust
pub async fn update_group(&self, user_id: i64, conversation_id: Uuid, name: Option<&str>, avatar: Option<&str>) -> Result<(), StatusCode>
```

逻辑：
1. 校验当前用户是群主
2. 如果 name 不为空，trim 后校验非空
3. 调 repo.update_group

---

## 任务 5：routes.rs 扩展 `✅ 已完成`

文件：`server/modules/im-group/src/routes.rs`（修改）

### 5.1 add_members handler `✅`

```rust
/// POST /groups/{id}/members
async fn add_members(State, headers, Path(conv_id), Json(req: AddMembersRequest)) -> Result<Json<...>, AppError>
```

逻辑：调 service.add_members → 查邀请者昵称 → send_system "XXX 邀请了 YYY、ZZZ 加入群聊" → 返回 added_count。

### 5.2 remove_member handler `✅`

```rust
/// DELETE /groups/{id}/members/{uid}
async fn remove_member(State, headers, Path((conv_id, target_id)))
```

逻辑：调 service.remove_member → 查被踢者昵称 → send_system "XXX 被移出群聊"。

### 5.3 leave handler `✅`

```rust
/// POST /groups/{id}/leave
async fn leave(State, headers, Path(conv_id))
```

逻辑：调 service.leave → 查退出者昵称 → send_system "XXX 退出了群聊"。

### 5.4 transfer_owner handler `✅`

```rust
/// PUT /groups/{id}/transfer
async fn transfer_owner(State, headers, Path(conv_id), Json(req: TransferOwnerRequest))
```

逻辑：调 service.transfer_owner → 查两人昵称 → send_system "XXX 将群主转让给了 YYY"。

### 5.5 disband handler `✅`

```rust
/// POST /groups/{id}/disband
async fn disband(State, headers, Path(conv_id))
```

逻辑：先 send_system "群聊已解散" → 再调 service.disband（顺序不能反）。

### 5.6 update_announcement handler `✅`

```rust
/// PUT /groups/{id}/announcement
async fn update_announcement(State, headers, Path(conv_id), Json(req: UpdateAnnouncementRequest))
```

逻辑：调 service.update_announcement → 查更新者昵称 → send_system "XXX 更新了群公告" → get_member_ids → notify_group_info_update 推送公告变更。

### 5.7 update_group handler `✅`

```rust
/// PUT /groups/{id}
async fn update_group(State, headers, Path(conv_id), Json(req: UpdateGroupRequest))
```

逻辑：调 service.update_group → 如果改名则查更新者昵称 → send_system "XXX 将群名修改为「YYY」" → get_member_ids → notify_group_info_update 推送群名/头像变更。

### 5.8 路由注册 `✅`

在 `group_routes` 中追加 7 个路由：

```rust
.route("/groups/{id}/members", post(add_members))
.route("/groups/{id}/members/{uid}", delete(remove_member_handler))
.route("/groups/{id}/leave", post(leave))
.route("/groups/{id}/transfer", put(transfer_owner))
.route("/groups/{id}/disband", post(disband))
.route("/groups/{id}/announcement", put(update_announcement))
.route("/groups/{id}", put(update_group))
```

---

## 任务 6：MessageService.send 拦截已解散群 `✅ 已完成`

文件：`server/modules/im-message/src/service.rs`（修改）

### 6.1 send 方法开头加 status 校验 `✅`

在 `send` 方法的成员校验之前，查 `conversations.status`：

```rust
let status: i16 = sqlx::query_as("SELECT COALESCE(status, 0::SMALLINT) FROM conversations WHERE id = $1")
    .bind(conversation_id)
    .fetch_one(&self.db)
    .await?;
if status == 1 {
    return Err(StatusCode::FORBIDDEN);  // 群聊已解散
}
```

注意：`send_system` 不受此限制（解散时需要发系统消息），只拦截普通用户的 `send`。

---

## 任务 7：GroupDetail 扩展 `✅ 已完成`

文件：`server/modules/im-group/src/` 多处修改

### 7.1 repository.get_group_info 返回值扩展 `✅`

增加返回 status、announcement、announcement_updated_at。

### 7.2 service.get_group_detail 组装扩展 `✅`

把 status 和 announcement 填入 GroupDetail。

---

## 任务 8：编译验证 + 接口测试 `✅ 已完成`

### 8.1 数据库迁移 `✅`

```bash
python scripts/server/reset_db.py
```

### 8.2 编译 `✅`

```bash
cargo build
```

### 8.3 接口测试脚本 `✅`

编写测试脚本覆盖：
- 邀请入群（成功 / 非成员 403 / 超过上限 400）
- 踢人（成功 / 非群主 403 / 踢自己 400）
- 退群（成功 / 群主退群 400）
- 转让（成功 / 非群主 403 / 新群主非成员 400）
- 解散（成功 / 非群主 403 / 解散后发消息被拦截）
- 群公告（发布 / 非群主 403 / 系统消息 + GROUP_INFO_UPDATE 推送）
- 修改群名（成功 / 群名为空 400 / 非群主 403 / 系统消息 + GROUP_INFO_UPDATE 推送）
- 群详情返回 status + announcement

---

## 任务 9：AppError 统一错误处理 `✅ 已完成`

文件：`server/modules/flash-core/src/error.rs`（新建）

### 9.1 AppError 结构体 `✅`

```rust
pub struct AppError {
    pub status: StatusCode,
    pub message: String,
    pub detail: Option<String>,  // 只打印到服务端日志，不返回给客户端
}
```

### 9.2 便捷方法 `✅`

- `AppError::bad_request(msg)` → 400
- `AppError::forbidden(msg)` → 403
- `AppError::not_found(msg)` → 404
- `AppError::internal(err, context)` → 500（带上下文标签）

### 9.3 自动转换 `✅`

- `From<sqlx::Error>` → 自动转为 500 + 打印详情
- `From<StatusCode>` → 兼容旧代码

### 9.4 IntoResponse 实现 `✅`

返回结构化 JSON：`{ "error": "...", "status": 400 }`，服务端日志打印错误详情。

---

## 任务 10：GROUP_INFO_UPDATE WS 帧 `✅ 已完成`

### 10.1 proto 定义 `✅`

文件：`proto/ws.proto`

```protobuf
enum WsFrameType {
    // ...
    GROUP_INFO_UPDATE = 11;
}
```

文件：`proto/message.proto`

```protobuf
message GroupInfoUpdate {
    string conversation_id = 1;
    optional string name = 2;
    optional string avatar = 3;
    optional string announcement = 4;
    optional int32 status = 5;
}
```

### 10.2 dispatcher 扩展 `✅`

文件：`server/modules/im-ws/src/dispatcher.rs`

```rust
pub async fn notify_group_info_update(
    &self,
    member_ids: &[i64],
    conversation_id: &str,
    name: Option<&str>,
    avatar: Option<&str>,
    announcement: Option<&str>,
    status: Option<i32>,
)
```

构造 GroupInfoUpdate proto 消息，封装为 WsFrame（type = GROUP_INFO_UPDATE），通过 `ws_state.send_to_users` 推送给所有群成员。

### 10.3 routes 层调用 `✅`

- `update_group` handler：改名时调 `notify_group_info_update`（推送 name/avatar）
- `update_announcement` handler：改公告时调 `notify_group_info_update`（推送 announcement）
- 均通过 `tokio::spawn` 异步推送，不阻塞 HTTP 响应
