# 消息操作 — 客户端任务清单

基于 [design.md](design.md) 设计。不新建模块，改动分布在 flash_im_core、flash_im_chat、flash_im_cache。
状态管理使用 Cubit，组件只管渲染通过回调通知 Cubit，Repository 只管数据存取。

---

## 执行顺序

### 阶段一：基础设施

1. ⬜ 任务 1 — WsClient 扩展（修改）
2. ⬜ 任务 2 — local_trash 表 + TrashDao（新建）
3. ⬜ 任务 3 — AppDatabase 注册 + drift 代码生成（修改 + 配置）
4. ⬜ 任务 4 — LocalStore 接口扩展（修改）
5. ⬜ 任务 5 — DriftLocalStore 实现 trash（修改）
6. ⬜ 任务 6 — SyncEngine 扩展（修改）

### 阶段二：状态层

7. ⬜ 任务 7 — Message 模型 + ChatState 扩展（修改）
8. ⬜ 任务 8 — MessageRepository 扩展（修改）
9. ⬜ 任务 9 — ChatCubit 扩展（修改，依赖任务 1、4、7、8）

### 阶段三：组件层

10. ⬜ 任务 10 — MessageActionMenu（新建）
11. ⬜ 任务 11 — ReplyBubble（新建）
12. ⬜ 任务 12 — ReplyPreviewBar（新建）

### 阶段四：集成层

13. ⬜ 任务 13 — MessageBubble 改造（修改，依赖任务 11）
14. ⬜ 任务 14 — ChatPage 改造（修改，依赖任务 10、13）
15. ⬜ 任务 15 — ChatInput 改造（修改，依赖任务 12）
16. ⬜ 任务 16 — barrel file + flutter analyze（配置）

---

## 任务 1：WsClient 扩展 `⬜`

文件：`client/modules/flash_im_core/lib/src/logic/ws_client.dart`（修改）

### 1.1 新增 messageRecalledStream `⬜`

```dart
final _messageRecalledController = StreamController<WsFrame>.broadcast();
Stream<WsFrame> get messageRecalledStream => _messageRecalledController.stream;
```

### 1.2 switch 分发新增 MESSAGE_RECALLED `⬜`

```dart
case WsFrameType.MESSAGE_RECALLED:
  _messageRecalledController.add(frame);
```

### 1.3 dispose 关闭 controller `⬜`

```dart
_messageRecalledController.close();
```

---

## 任务 2：local_trash 表 + TrashDao `⬜`

### 2.1 LocalTrashTable `⬜`

文件：`client/modules/flash_im_cache/lib/src/drift/database/tables/local_trash_table.dart`（新建）

```dart
class LocalTrashTable extends Table {
  TextColumn get entityId => text()();
  TextColumn get entityType => text()();  // message / conversation
  IntColumn get deletedAt => integer()();

  @override
  Set<Column> get primaryKey => {entityId};
}
```

### 2.2 TrashDao `⬜`

文件：`client/modules/flash_im_cache/lib/src/drift/dao/trash_dao.dart`（新建）

```dart
class TrashDao {
  final AppDatabase _db;
  TrashDao(this._db);

  Future<void> moveToTrash(String entityId, String entityType) async
  // → insertOnConflictUpdate

  Future<void> restoreFromTrash(String entityId) async
  // → delete where entityId

  Future<bool> isInTrash(String entityId) async
  // → select count

  Future<List<String>> getTrashIds({String? entityType}) async
  // → select entityId, 可选按 entityType 过滤
}
```

---

## 任务 3：AppDatabase 注册 + drift 代码生成 `⬜`

### 3.1 AppDatabase 注册 LocalTrashTable `⬜`

文件：`client/modules/flash_im_cache/lib/src/drift/database/app_database.dart`（修改）

```dart
@DriftDatabase(tables: [
  CachedMessagesTable, CachedConversationsTable, CachedFriendsTable,
  LocalTrashTable,  // 新增
])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 2;  // 1 → 2

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(localTrashTable);
      }
    },
  );
}
```

### 3.2 运行代码生成 `⬜`

```bash
cd client/modules/flash_im_cache
dart run build_runner build --delete-conflicting-outputs
```

---

## 任务 4：LocalStore 接口扩展 `⬜`

文件：`client/modules/flash_im_cache/lib/src/local_store.dart`（修改）

```dart
// 新增方法
Future<void> moveToTrash(String entityId, String entityType);
Future<void> restoreFromTrash(String entityId);
Future<List<String>> getTrashIds({String? entityType});
```

---

## 任务 5：DriftLocalStore 实现 trash `⬜`

文件：`client/modules/flash_im_cache/lib/src/drift/drift_local_store.dart`（修改）

### 5.1 新增 TrashDao 字段 `⬜`

```dart
late final TrashDao _trashDao;
// 构造函数中初始化
_trashDao = TrashDao(_db);
```

### 5.2 实现三个 trash 方法 `⬜`

```dart
@override
Future<void> moveToTrash(String entityId, String entityType) async {
  await _trashDao.moveToTrash(entityId, entityType);
}
// restoreFromTrash、getTrashIds 同理
```

---

## 任务 6：SyncEngine 扩展 `⬜`

文件：`client/modules/flash_im_cache/lib/src/sync_engine.dart`（修改）

### 6.1 监听 messageRecalledStream `⬜`

```dart
_subs.add(_wsClient.messageRecalledStream.listen(_handleMessageRecalled));
```

### 6.2 _handleMessageRecalled 实现 `⬜`

解析 MessageRecalled protobuf，更新本地消息 status=1：

```dart
void _handleMessageRecalled(WsFrame frame) {
  final recalled = MessageRecalled.fromBuffer(frame.payload);
  // 更新本地缓存中该消息的 status
  // 通过 LocalStore 的 updateMessageStatus 或直接操作
}
```

需要在 LocalStore 新增 `updateMessageStatus` 方法，或在 SyncEngine 里直接用 Dio 拉最新消息覆盖。

---

## 任务 7：Message 模型 + ChatState 扩展 `⬜`

### 7.1 Message 新增 isRecalled `⬜`

文件：`client/modules/flash_im_chat/lib/src/data/message.dart`（修改）

```dart
bool get isRecalled => status == MessageStatus.sent && seq > 0;
// 需要新增 status 的 recalled 值，或用 int 判断
```

### 7.2 ChatState 新增字段 `⬜`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_state.dart`（修改）

```dart
class ChatLoaded extends ChatState {
  // 已有字段...
  final Message? replyTo;
  final bool isMultiSelect;
  final Set<String> selectedIds;

  // copyWith 新增对应参数
}
```

---

## 任务 8：MessageRepository 扩展 `⬜`

文件：`client/modules/flash_im_chat/lib/src/data/message_repository.dart`（修改）

### 8.1 recallMessage API `⬜`

```dart
Future<void> recallMessage(String conversationId, String messageId) async {
  await _dio.post('/conversations/$conversationId/messages/$messageId/recall');
}
```

### 8.2 getMessages 过滤回收站 `⬜`

读取后过滤掉 local_trash 中的消息 ID：

```dart
if (_store != null) {
  final cached = await _store!.getMessages(...);
  final trashIds = await _store!.getTrashIds(entityType: 'message');
  final filtered = cached.where((m) => !trashIds.contains(m.id)).toList();
  if (filtered.isNotEmpty) return filtered.map(_fromCached).toList();
}
```

---

## 任务 9：ChatCubit 扩展 `⬜`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_cubit.dart`（修改）

### 9.1 撤回逻辑 `⬜`

```dart
Future<void> recallMessage(String messageId) async
// 1. 调 _repository.recallMessage
// 2. 本地立即替换为撤回提示（_replaceWithRecalled）

void _handleMessageRecalled(WsFrame frame)
// 1. 解析 MessageRecalled
// 2. 如果是当前会话，替换展示
```

新增 `_messageRecalledSub` 订阅 + dispose 取消。

### 9.2 引用逻辑 `⬜`

```dart
void setReplyTo(Message message)
// emit ChatLoaded.copyWith(replyTo: message)

void clearReplyTo()
// emit ChatLoaded.copyWith(clearReplyTo: true)
```

sendMessage 改造：如果 replyTo != null，在 extra 里携带 reply_to 对象。

### 9.3 多选逻辑 `⬜`

```dart
void enterMultiSelect(String initialId)
// emit ChatLoaded.copyWith(isMultiSelect: true, selectedIds: {initialId})

void exitMultiSelect()
// emit ChatLoaded.copyWith(isMultiSelect: false, selectedIds: {})

void toggleSelect(String messageId)
// 添加或移除 selectedIds

Future<void> deleteSelected() async
// 遍历 selectedIds，调 _store.moveToTrash，然后 exitMultiSelect + reload
```

### 9.4 复制与删除 `⬜`

```dart
void copyMessage(String content)
// Clipboard.setData + Toast

Future<void> deleteMessage(String messageId) async
// _store.moveToTrash + reload
```

---

## 任务 10：MessageActionMenu `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/message_action_menu.dart`（新建）

职责：长按菜单 Overlay 组件，只管渲染和定位，通过回调通知外部。

```dart
class MessageActionMenu {
  static void show({
    required BuildContext context,
    required LayerLink layerLink,
    required Message message,
    required bool isMe,
    required void Function(MenuAction action) onAction,
  })
  // 1. 计算位置（上方/下方）
  // 2. 创建 OverlayEntry
  // 3. 渲染菜单项（根据 message 类型和 isMe 动态过滤）
  // 4. 点击菜单项 → onAction 回调 + 关闭
  // 5. 点击遮罩 → 关闭
}

enum MenuAction { copy, reply, recall, delete, multiSelect }
```

样式：深色气泡背景，圆角 8，水平排列图标 + 文字。

---

## 任务 11：ReplyBubble `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/bubble/reply_bubble.dart`（新建）

职责：引用内容嵌套组件，只管渲染。

```dart
class ReplyBubble extends StatelessWidget {
  final String senderName;
  final String content;
  final int msgType;
  // 渲染：灰色背景 + 左侧蓝色竖线 + 发送者名 + 内容摘要
  // 内容摘要：文本截前 30 字，图片→[图片]，视频→[视频]，文件→[文件]
}
```

---

## 任务 12：ReplyPreviewBar `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/reply_preview_bar.dart`（新建）

职责：输入框上方引用预览条，只管渲染。

```dart
class ReplyPreviewBar extends StatelessWidget {
  final String senderName;
  final String content;
  final VoidCallback onClose;
  // 渲染：灰色横条 + "回复 XXX：内容摘要" + 右侧关闭按钮
}
```

---

## 任务 13：MessageBubble 改造 `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/bubble/message_bubble.dart`（修改）

### 13.1 撤回展示 `⬜`

status=1 时显示居中灰色标签（和系统消息样式一致），文案根据 isMe 区分。

### 13.2 引用气泡嵌套 `⬜`

如果 message.extra 包含 reply_to，在气泡内容上方嵌套 ReplyBubble。

### 13.3 多选勾选框 `⬜`

isMultiSelect 时，消息左侧显示 Checkbox，选中状态由外部传入。

新增参数：`isMultiSelect`、`isSelected`、`onToggleSelect`、`onLongPress`。

---

## 任务 14：ChatPage 改造 `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/chat_page.dart`（修改）

### 14.1 长按手势 `⬜`

MessageBubble 外包 GestureDetector + CompositedTransformTarget，长按时调用 MessageActionMenu.show。

### 14.2 多选模式 UI `⬜`

isMultiSelect 时：
- AppBar 标题变为"已选择 N 条"
- 底部 ChatInput 替换为操作栏（删除 + 取消）
- 消息列表传入 isMultiSelect / isSelected / onToggleSelect

### 14.3 菜单回调处理 `⬜`

```dart
void _handleMenuAction(MenuAction action, Message message) {
  switch (action) {
    case MenuAction.copy: cubit.copyMessage(message.content);
    case MenuAction.reply: cubit.setReplyTo(message);
    case MenuAction.recall: cubit.recallMessage(message.id);
    case MenuAction.delete: cubit.deleteMessage(message.id);
    case MenuAction.multiSelect: cubit.enterMultiSelect(message.id);
  }
}
```

---

## 任务 15：ChatInput 改造 `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/chat_input.dart`（修改）

### 15.1 引用预览条集成 `⬜`

新增参数 `replyTo` 和 `onCancelReply`。输入框上方条件渲染 ReplyPreviewBar。

### 15.2 发送时携带 replyTo `⬜`

onSend 回调改为携带 replyTo 信息，或由 ChatCubit 在 sendMessage 时自动读取 state.replyTo。

---

## 任务 16：barrel file + flutter analyze `⬜`

### 16.1 barrel file 更新 `⬜`

文件：`client/modules/flash_im_chat/lib/flash_im_chat.dart`（修改）

导出新组件：MessageActionMenu、ReplyBubble、ReplyPreviewBar。

### 16.2 flutter analyze `⬜`

```bash
cd client
flutter analyze
```

确保无错误。
