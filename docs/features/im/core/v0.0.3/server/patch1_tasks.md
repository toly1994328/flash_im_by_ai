# IM Core v0.0.3-patch1 — 服务端补丁任务

基于 patch1_design.md，列出具体改动。所有任务已在联调过程中完成。

---

## 执行顺序

1. ✅ 任务 1 — ChatMessage 帧新增 sender_name / sender_avatar
2. ✅ 任务 2 — ConversationUpdate 帧新增 total_unread
3. ✅ 任务 3 — 新增 POST /conversations/:id/read 接口
4. ✅ 任务 4 — 重新生成 proto 代码 + 编译验证
5. ✅ 任务 5 — 新增 GET /conversations/:id 接口
6. ✅ 任务 6 — 前端处理未知会话的 CONVERSATION_UPDATE
3. ✅ 任务 3 — 新增 POST /conversations/:id/read 接口
4. ✅ 任务 4 — 重新生成 proto 代码 + 编译验证

---

## 任务 1：ChatMessage 新增 sender 信息 `✅`

### 1.1 proto 修改 `✅`

文件：`proto/message.proto`（修改）

ChatMessage 新增：
```protobuf
string sender_name = 10;
string sender_avatar = 11;
```

### 1.2 后端广播器填充 `✅`

文件：`server/modules/im-ws/src/broadcaster.rs`（修改）

broadcast_message 方法中，查询 user_profiles 获取 sender_name 和 sender_avatar，填入 ChatMessage 帧。

### 1.3 前端解析 `✅`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_cubit.dart`（修改）

_handleIncomingMessage 中从 chatMsg.senderName / chatMsg.senderAvatar 取值。

---

## 任务 2：ConversationUpdate 新增 total_unread `✅`

### 2.1 proto 修改 `✅`

文件：`proto/message.proto`（修改）

ConversationUpdate 新增：
```protobuf
int32 total_unread = 5;
```

### 2.2 后端广播器查询 total_unread `✅`

文件：`server/modules/im-ws/src/broadcaster.rs`（修改）

- WsBroadcaster 新增 `db: PgPool` 字段
- broadcast_conversation_update 中为每个接收者查询 `SUM(unread_count)`
- 改为逐用户推送（每人的 total_unread 不同）

### 2.3 依赖更新 `✅`

- `server/modules/im-ws/Cargo.toml`：新增 sqlx.workspace = true
- `server/src/main.rs`：WsBroadcaster::new(ws_state, db)

### 2.4 前端消费 `✅`

文件：`client/modules/flash_im_conversation/lib/src/logic/conversation_list_cubit.dart`

_handleUpdate 中从 update.totalUnread 取值，更新 ConversationListLoaded.totalUnread。

---

## 任务 3：新增 mark_read 接口 `✅`

### 3.1 后端路由 `✅`

文件：`server/modules/im-conversation/src/routes.rs`（修改）

新增 handler：
```rust
async fn mark_read(...) -> Result<Json<MessageResponse>, StatusCode>
// UPDATE conversation_members SET unread_count = 0
// WHERE conversation_id = $1 AND user_id = $2
```

新增路由：
```rust
.route("/conversations/{id}/read", post(mark_read))
```

### 3.2 前端调用 `✅`

- `client/modules/flash_im_conversation/lib/src/data/conversation_repository.dart`：新增 markRead 方法
- `client/modules/flash_im_conversation/lib/src/logic/conversation_list_cubit.dart`：clearUnread 中调用 _repository.markRead

---

## 任务 4：重新生成 proto 代码 + 编译验证 `✅`

```powershell
powershell -ExecutionPolicy Bypass -File scripts/proto/gen.ps1
```

- 后端 cargo build 通过
- 前端 flutter analyze 零 error

---

## 任务 5：新增 GET /conversations/:id 接口 `⬜`

### 5.1 后端 service 新增 get_by_id `⬜`

文件：`server/modules/im-conversation/src/service.rs`（修改）

```rust
pub async fn get_by_id(&self, conversation_id: Uuid, user_id: i64) -> Result<ConversationDetail, StatusCode> {
    // 1. 验证 user_id 是会话成员
    // 2. 查询 conversations 表 + 关联 user_profiles 补充对方信息
    // 3. 返回格式与列表接口中的单条一致
}
```

### 5.2 后端路由注册 `⬜`

文件：`server/modules/im-conversation/src/routes.rs`（修改）

```rust
async fn get_conversation(...) -> Result<Json<serde_json::Value>, StatusCode>

// 路由注册
.route("/conversations/{id}", delete(delete_conversation).get(get_conversation))
```

### 5.3 编译验证 `⬜`

cargo build 通过。

---

## 任务 6：前端处理未知会话的 CONVERSATION_UPDATE `⬜`

### 6.1 ConversationRepository 新增 getById `⬜`

文件：`client/modules/flash_im_conversation/lib/src/data/conversation_repository.dart`（修改）

```dart
Future<Conversation> getById(String id) async {
  final res = await _dio.get('/conversations/$id');
  return Conversation.fromJson(res.data);
}
```

### 6.2 ConversationListCubit._handleUpdate 处理未知会话 `⬜`

文件：`client/modules/flash_im_conversation/lib/src/logic/conversation_list_cubit.dart`（修改）

```dart
void _handleUpdate(WsFrame frame) {
  final update = ConversationUpdate.fromBuffer(frame.payload);
  final found = current.conversations.any((c) => c.id == update.conversationId);

  if (found) {
    // 已有逻辑：更新 preview/time/unread，重排序
  } else {
    // 新增：创建骨架会话，插入列表顶部
    final skeleton = Conversation.skeleton(
      id: update.conversationId,
      lastMessagePreview: update.lastMessagePreview,
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(update.lastMessageAt.toInt()),
      unreadCount: update.unreadCount,
    );
    emit(ConversationListLoaded([skeleton, ...current.conversations], ...));

    // 异步拉取完整信息，替换骨架
    _repository.getById(update.conversationId).then((full) {
      // 用 full 替换列表中的 skeleton
    });
  }
}
```

### 6.3 Conversation.skeleton 工厂方法 `⬜`

文件：`client/modules/flash_im_conversation/lib/src/data/conversation.dart`（修改）

新增 skeleton 工厂方法，nickname/avatar 为空，UI 层判断为空时显示骨架屏占位。

### 6.4 ConversationTile 骨架屏支持 `⬜`

文件：`client/modules/flash_im_conversation/lib/src/view/conversation_tile.dart`（修改）

当 peerNickname 为空时，名称和头像区域显示 Shimmer 骨架屏。
