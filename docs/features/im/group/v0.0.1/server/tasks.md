# 群聊（创建与加入） — 服务端任务清单

基于 [design.md](design.md) 设计，列出需要创建/修改的具体细节。

全局约束：
- 群聊路由（搜索/入群/审批）放在 `server/src/group_routes.rs`（顶层），因为 `im-conversation` 不能依赖 `im-ws`（会形成循环：im-conversation → im-ws → im-message → im-conversation）
- 创建群聊（POST /conversations type=group）放在 `im-conversation/routes.rs`（不需要 dispatcher）
- 错误处理统一用 `StatusCode` 返回
- SQL 使用参数化查询
- 参考项目路径：`docs/ref/flash_im-main/backend/crates/im-conversation/`

---

## 执行顺序

1. ✅ 任务 1 — 数据库迁移
2. ✅ 任务 2 — Protobuf 定义
3. ✅ 任务 3 — im-conversation/models.rs 扩展
4. ✅ 任务 4 — im-conversation/repository.rs 扩展
5. ✅ 任务 5 — im-conversation/service.rs 扩展
6. ✅ 任务 6 — im-ws/dispatcher.rs 扩展
7. ✅ 任务 7 — im-conversation/routes.rs 改造 + server/src/group_routes.rs 新建
8. ✅ 任务 8 — main.rs 组装
9. ✅ 任务 9 — 编译验证
10. ✅ 任务 10 — HTTP 发消息接口
11. ✅ 任务 11 — 系统用户 + send_system 方法
12. ✅ 任务 12 — 创建群聊自动发系统消息
13. ✅ 任务 13 — GET /conversations type 过滤
14. ✅ 任务 14 — 移除搜索/入群/审批代码
15. ⬜ 任务 15 — 拆分 im-group 独立 crate

---

## 任务 1：数据库迁移 `✅ 已完成`

- ✅ 新建 `server/migrations/20260412_005_group.sql`（group_info + 系统用户）
- ✅ 注册到 `scripts/server/reset_db.py` 的 MIGRATIONS 列表
- ✅ `python scripts/server/reset_db.py` 验证通过

## 任务 2：Protobuf 定义 `✅ 已完成`

- ✅ `proto/ws.proto` 新增 `GROUP_JOIN_REQUEST = 10` 帧类型
- ✅ `proto/ws.proto` 新增 `GroupJoinRequestNotification` 消息
- ✅ `python scripts/proto/gen.py` 生成前后端代码

## 任务 3：models.rs 扩展 `✅ 已完成`

- ✅ `CreatePrivateRequest` 替换为统一的 `CreateConversationRequest`（type/peer_user_id/name/member_ids）
- ✅ `CreateConversationResponse` 扩展支持群聊字段（name/avatar/owner_id 可选）
- ✅ 新增 `GroupSearchResult`、`GroupJoinRequest`、`MyJoinRequestItem`、`JoinGroupInput`、`HandleJoinInput`、`JoinGroupResponse`、`SearchQuery`

## 任务 4：repository.rs 扩展 `✅ 已完成`

- ✅ `create_group` — 事务创建群聊 + 成员 + group_info + 宫格头像
- ✅ `build_grid_avatar` — 查前 9 个成员头像拼接 `grid:url1,url2,...`
- ✅ `add_member` — 单个成员加入（ON CONFLICT 恢复 is_deleted）
- ✅ `find_by_id` — 根据 ID 查询会话
- ✅ `is_member` — 检查用户是否是会话成员
- ✅ `search_groups` — 按群名 ILIKE 搜索，关联 member_count/is_member/join_verification
- ✅ `get_group_join_verification` — 查询入群验证开关
- ✅ `create_join_request` / `find_pending_join_request` / `find_join_request_by_id` / `update_join_request_status`
- ✅ `get_my_pending_join_requests` — 群主的所有待处理申请（带用户信息+群名）

## 任务 5：service.rs 扩展 `✅ 已完成`

- ✅ `db()` getter 暴露数据库连接池
- ✅ `create_private` 返回值适配新的 `CreateConversationResponse`
- ✅ `create_group` — 校验群名/成员数 + 调用 repo
- ✅ `search_groups` — 空关键词返回空列表
- ✅ `request_join` — 校验群存在/非成员/无待处理申请 → 分支：直接加入 or 创建申请
- ✅ `handle_join_request` — 校验申请状态/群主身份 → 同意加入+刷新头像 or 拒绝
- ✅ `get_my_join_requests`

## 任务 6：dispatcher.rs 扩展 `✅ 已完成`

- ✅ 新增 `notify_group_join_request` 方法（构造 GroupJoinRequestNotification → WS 推送给群主）
- ✅ import 新增 `GroupJoinRequestNotification`

## 任务 7：路由 `✅ 已完成`

架构决策：群聊路由放在 `server/src/group_routes.rs`（避免 im-conversation → im-ws 循环依赖）

- ✅ `im-conversation/routes.rs`：`create_conversation` 改为统一入口（type=private/group 分发）
- ✅ `server/src/group_routes.rs`（新建）：`GroupApiState` + search_groups / join_group / handle_join_request / get_my_join_requests
- ✅ `join_group` handler 中：需审批时查询申请者信息 + WS 通知群主

## 任务 8：main.rs 组装 `✅ 已完成`

- ✅ `mod group_routes` 声明
- ✅ 创建 `GroupApiState` 注入 service + dispatcher
- ✅ `.merge(group_routes(group_api_state))` 注册路由

## 任务 9：编译验证 `✅ 已完成`

- ✅ `cargo build` 零错误零 warning
- ⬜ 启动服务 + 手动测试（待执行）

## 任务 10：HTTP 发消息接口 `✅ 已完成`

- ✅ `im-message/routes.rs` 新增 `POST /conversations/{id}/messages` handler
- ✅ 走 `MessageService.send` 完整链路（存储+广播+会话更新）
- ✅ 请求体：`{ content, msg_type?, extra? }`

## 任务 11：系统用户 + send_system 方法 `✅ 已完成`

- ✅ `20260412_005_group.sql` 追加系统用户 INSERT（id=999999999, nickname='系统通知'）
- ✅ `im-message/service.rs` 新增 `send_system(conversation_id, content)` 方法
- ✅ 跳过成员校验，sender_id=999999999，走完整流程（seq→存储→广播）
- ✅ `CreateConversationRequest.conv_type` 加 serde default = "private" 兼容旧格式

## 任务 12：创建群聊自动发系统消息 `✅ 已完成`

- ✅ 创建群聊路由从 `im-conversation/routes.rs` 移到 `group_routes.rs`（需要 MessageService）
- ✅ `GroupApiState` 新增 `msg_service: Arc<MessageService>`
- ✅ 创建群聊成功后调 `msg_service.send_system(conv_id, "XXX 创建了群聊")`
- ✅ `main.rs` 注入 msg_service 到 GroupApiState

## 任务 13：GET /conversations type 过滤 `✅ 已完成`

- ✅ `im-conversation/routes.rs` list_conversations 新增可选 `type` 查询参数
- ✅ `im-conversation/service.rs` get_list 签名新增 `conv_type: Option<i16>` 参数
- ✅ `im-conversation/repository.rs` list_by_user 动态拼接 `AND c.type = $4` 条件
- ✅ 不传 type 时行为不变（返回所有会话），传 `type=1` 只返回群聊

## 任务 14：移除搜索/入群/审批代码 `✅ 已完成`

搜索加群、入群申请、群主审批的前后端代码全部移除。

- ✅ `group_routes.rs` 移除 search_groups / join_group / handle_join_request / get_my_join_requests 四个路由，只保留 create_conversation
- ✅ `GroupApiState` 移除 `dispatcher` 字段（不再需要 WS 推送）
- ✅ `main.rs` GroupApiState 构造移除 dispatcher 注入
- ✅ `service.rs` 移除 search_groups / request_join / handle_join_request / get_my_join_requests 四个方法
- ✅ `repository.rs` 移除 search_groups / get_group_join_verification / create_join_request / find_pending_join_request / find_join_request_by_id / update_join_request_status / get_my_pending_join_requests 七个方法
- ✅ `models.rs` 移除 GroupSearchResult / GroupJoinRequest / MyJoinRequestItem / JoinGroupInput / HandleJoinInput / JoinGroupResponse / SearchQuery 七个模型
- ✅ `dispatcher.rs` 移除 notify_group_join_request 方法和 GroupJoinRequestNotification import
- ✅ `proto/ws.proto` 移除 GROUP_JOIN_REQUEST 帧类型和 GroupJoinRequestNotification 消息
- ✅ `python scripts/proto/gen.py` 重新生成前后端代码

## 任务 15：新建 im-group 独立 crate `⬜ 待处理`

群聊相关代码放在独立的 im-group crate 中。会话模块只管通讯能力，群的事情归群管。

### 15.1 新建 im-group crate `⬜`

- 新建 `server/modules/im-group/`（Cargo.toml + src/lib.rs）
- 在 workspace Cargo.toml 中注册 im-group
- 依赖：flash-core（PgPool, JWT）、im-message（MessageService，用于 send_system）

### 15.2 模型 `⬜`

- `im-group/src/models.rs`：CreateGroupRequest（群名 + 成员列表）

### 15.3 repository `⬜`

- `im-group/src/repository.rs`：create_group 事务 + build_grid_avatar

### 15.4 service `⬜`

- `im-group/src/service.rs`：create_group 校验 + 事务编排

### 15.5 路由 `⬜`

- `im-group/src/routes.rs`：POST /groups 创建群聊 + 发系统消息
- GroupApiState 定义在 im-group 内部

### 15.6 main.rs 注册 `⬜`

- 新增 `im-group` 依赖
- 注册 im-group 路由

### 15.7 编译验证 `⬜`

- `cargo build` 零错误
- `python scripts/server/reset_db.py` 通过
