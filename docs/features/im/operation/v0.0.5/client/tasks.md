# 会话列表操作 — 客户端任务清单

基于 [design.md](design.md) 设计。改动分布在 flash_im_conversation、flash_im_core、flash_im_cache、proto 四个模块。

---

## 执行顺序

### 阶段一：数据与协议

1. ✅ 任务 1 — Proto 扩展：ConversationUpdate 加 optional 字段（无依赖）
2. ✅ 任务 2 — CachedConversation 模型扩展（无依赖）

### 阶段二：数据层

3. ✅ 任务 3 — Conversation 模型扩展 + copyWith 补全（依赖任务 1）
4. ✅ 任务 4 — ConversationRepository 扩展 toggle + markUnread（依赖任务 3）
5. ✅ 任务 5 — ConversationMenuAction 枚举 + getActions 决策（无依赖）

### 阶段三：业务逻辑

6. ✅ 任务 6 — ConversationListCubit 改造（依赖任务 3、4、5）
7. ✅ 任务 7 — SyncEngine 同步 ConversationUpdate 补充字段（依赖任务 2）

### 阶段四：UI

8. ✅ 任务 8 — 新增依赖：flutter_slidable + fx_env + tolyui_feedback
9. ✅ 任务 9 — ConversationContextMenu（桌面端右键菜单）（依赖任务 5）
10. ✅ 任务 10 — ConversationDeleteDialog（删除/清空确认弹窗）（依赖任务 9）
11. ✅ 任务 11 — ConversationTile 集成交互（依赖任务 5、9、10）
12. ✅ 任务 12 — ConversationListPage 分区渲染（依赖任务 6、11）

### 阶段五：验证

13. ✅ 任务 13 — dart analyze 零错误

---

## 任务 1：Proto 扩展 `✅ 已完成`

文件：`proto/message.proto`（修改）

### 1.1 扩展 `ConversationUpdate` 消息 `✅`

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

### 1.2 重新生成 Dart proto 代码 `✅`

```bash
cd proto && protoc --dart_out=../client/modules/flash_im_core/lib/src/data/proto ...
```

改动类型：修改文件 + 重新生成。

---

## 任务 2：CachedConversation 模型扩展 `✅ 已完成`

文件：`client/modules/flash_im_cache/lib/src/models/cached_conversation.dart`（修改）

### 2.1 新增 `isPinned`、`isMuted`、`pinnedAt` 字段 `✅`

```dart
class CachedConversation {
  // ... 已有字段不变 ...
  final bool isPinned;      // 新增
  final bool isMuted;       // 新增
  final int? pinnedAt;      // 新增，毫秒时间戳，置顶时间
}
```

### 2.2 构造函数补全默认值 `✅`

```dart
const CachedConversation({
  // ... 已有参数 ...
  this.isPinned = false,
  this.isMuted = false,
  this.pinnedAt,
});
```

改动类型：修改文件，无依赖。

---

## 任务 3：Conversation 模型扩展 `✅ 已完成`

文件：`client/modules/flash_im_conversation/lib/src/data/conversation.dart`（修改）

### 3.1 新增 `pinnedAt` 字段 `✅`

```dart
final DateTime? pinnedAt; // 置顶时间，NULL 表示未置顶
```

### 3.2 `copyWith` 扩展 `✅`

补 `isPinned`、`isMuted`、`pinnedAt` 三个参数，并新增 `clearPreview` 标志位：

```dart
Conversation copyWith({
  // ... 已有参数 ...
  bool? isPinned,
  bool? isMuted,
  DateTime? pinnedAt,
  bool clearPreview = false,  // true 时强制清空 lastMessagePreview/lastMessageAt
});
```

> `clearPreview` 解决 `??` 操作符导致传入 `null` 无法清空字段的问题。

### 3.3 `fromJson` 补 `pinned_at` 解析 `✅`

```dart
pinnedAt: json['pinned_at'] != null
    ? DateTime.parse(json['pinned_at'] as String)
    : null,
```

改动类型：修改文件，依赖任务 1。

---

## 任务 4：ConversationRepository 扩展 `✅ 已完成`

文件：`client/modules/flash_im_conversation/lib/src/data/conversation_repository.dart`（修改）

### 4.1 `togglePin` — 翻转置顶状态 `✅`

```dart
/// 翻转置顶状态，返回新的 is_pinned 值
Future<bool> togglePin(String conversationId) async {
  final res = await _dio.post('/conversations/$conversationId/pin');
  return res.data['is_pinned'] as bool;
}
```

### 4.2 `toggleMute` — 翻转免打扰状态 `✅`

```dart
/// 翻转免打扰状态，返回新的 is_muted 值
Future<bool> toggleMute(String conversationId) async {
  final res = await _dio.post('/conversations/$conversationId/mute');
  return res.data['is_muted'] as bool;
}
```

### 4.3 `markUnread` — 标记未读 `✅`

```dart
/// 标记未读，返回新的 unread_count 值
Future<int> markUnread(String conversationId) async {
  final res = await _dio.post('/conversations/$conversationId/unread');
  return res.data['unread_count'] as int;
}
```

### 4.4 `_fromCached` 补新字段映射 `✅`

```dart
isPinned: c.isPinned,
isMuted: c.isMuted,
pinnedAt: c.pinnedAt != null
    ? DateTime.fromMillisecondsSinceEpoch(c.pinnedAt!)
    : null,
```

改动类型：修改文件，依赖任务 3。

---

## 任务 5：ConversationMenuAction 枚举 `✅ 已完成`

文件：`client/modules/flash_im_conversation/lib/src/data/conversation_menu_action.dart`（新建）

### 5.1 枚举定义 `✅`

```dart
enum ConversationMenuAction {
  pin,         // 置顶/取消置顶
  mute,        // 免打扰/取消免打扰
  markRead,    // 标为已读（仅 unreadCount > 0）
  markUnread,  // 标为未读
  delete,      // 删除会话
  clearAll,    // 清空当前会话聊天记录
}
```

### 5.2 `getConversationActions()` — 决策逻辑 `✅`

- 滑动菜单（`isSlidableView: true`）：pin、mute、markRead（条件）、delete
- 全量菜单（`isSlidableView: false`）：上述 4 个 + markUnread + clearAll

### 5.3 `actionInfo()` — 图标+文案映射 `✅`

根据 action + conv 状态返回对应 (IconData, String)，如置顶已置顶时显示"取消置顶"。

### 5.4 `slideActionColor()` — 滑动按钮颜色 `✅`

- pin: 蓝 `#3B82F6`、mute: 黄 `#F59E0B`、markRead: 绿 `#10B981`、delete: 红 `#FF4D4F`

改动类型：新建文件，无依赖。

---

## 任务 6：ConversationListCubit 改造 `✅ 已完成`

文件：`client/modules/flash_im_conversation/lib/src/logic/conversation_list_cubit.dart`（修改）

### 6.1 `_handleUpdate` 扩展 WS 字段处理 + clearedAt 过滤 `✅`

```dart
Future<void> _handleUpdate(WsFrame frame) async {
  // 1. 处理 is_deleted：从列表移除 + totalUnread 扣减
  // 2. 未知会话：插入骨架 → 异步补全后 await _ensureClearedAtMapLoaded() + _applyClearedAtToPreviews()
  // 3. 已知会话：c.copyWith(isPinned/muted/pinnedAt) + await _ensureClearedAtMapLoaded() + _applyClearedAtToPreviews()
  // 4. _sortWithPinned(updated)
}
```

> 改为 `async` 以支持 await `_ensureClearedAtMapLoaded()`，确保 WS 推送在列表加载前到达时 clearedAt 过滤仍生效。

### 6.2 `togglePin` — 乐观更新 + 失败回滚 `✅`

```dart
Future<void> togglePin(String conversationId) async {
  // 1. 保存 prev 状态
  // 2. _patchAndEmit: isPinned = !isPinned, pinnedAt = now/null
  // 3. await _repository.togglePin(id)
  // 4. catch → 回滚 prev
}
```

### 6.3 `toggleMute` — 同 togglePin 模式 `✅`

```dart
Future<void> toggleMute(String conversationId) async {
  // 1. 保存 prev → 2. _patchAndEmit isMuted toggle → 3. HTTP → 4. 回滚
}
```

### 6.4 `markUnread` — 乐观设 unreadCount=1 `✅`

```dart
Future<void> markUnread(String conversationId) async {
  // _patchAndEmit: unreadCount=1 → HTTP → 回滚
}
```

### 6.5 `_sortWithPinned` — 置顶分区排序 `✅`

```dart
void _sortWithPinned(List<Conversation> list) {
  // 置顶区 → 按 pinnedAt 倒序（null 用 createdAt fallback）
  // 普通区 → 按 lastMessageAt 倒序
}
```

### 6.6 `_patchAndEmit` — 单会话更新辅助 `✅`

查找到目标会话 → mapper 回调更新 → `_sortWithPinned` → `_applyClearedAtToPreviews` → emit。

> 每次 emit 前调用 `_applyClearedAtToPreviews` 确保所有会话的 clearedAt 过滤一致生效。

### 6.7 `clearMessages` — 清空当前会话聊天记录 `✅`

```dart
static const _clearedMapKey = 'conv_cleared_at_map';

Future<void> clearMessages(String conversationId) async {
  // 1. 读取 JSON Map → 写入 convId: DateTime.now().toUtc().toIso8601String() → 写回 SharedPrefs
  // 2. 删除 SQLite 缓存消息
  // 3. 本地更新预览：_patchAndEmit(conversationId, (c) => c.copyWith(
  //      clearPreview: true, unreadCount: 0,
  //    ));
  // 4. ConversationClearedEvent(conversationId: conversationId).emit()
  //    → 通知 ChatCubit 立刻重新过滤已加载消息
}
```

> `clearPreview: true`：因 `copyWith` 的 `??` 无法区分「不传」和「传 null」，新增此标志位确保 `lastMessagePreview`/`lastMessageAt` 被正确设为 null。`ConversationClearedEvent` 通过 FxEvent 总线通知消息模块立刻清空右侧消息列表。

### 6.8 `getClearedAt` — 查询清空时间戳 `✅`

```dart
Future<DateTime?> getClearedAt(String conversationId) async {
  // 读取 SharedPrefs Map → 解析 convId 对应的 ISO8601 → 返回 DateTime
}
```

> 消息模块通过 `cubit.getClearedAt(conversationId)` 获取时间戳，过滤 `sent_at < clearedAt` 的消息。纯本地操作，不调后端 API。
```

同时在 `loadConversations()` 和 `loadMore()` 中调用此过滤。

改动类型：修改文件，依赖任务 3、4、5。

---

## 任务 7：SyncEngine 同步补充 `✅ 已完成`

文件：`client/modules/flash_im_cache/lib/src/sync_engine.dart`（修改）

### 7.1 `_jsonToConversation` 补新字段解析 `✅`

```dart
isPinned: json['is_pinned'] as bool? ?? false,
isMuted: json['is_muted'] as bool? ?? false,
pinnedAt: json['pinned_at'] != null
    ? DateTime.parse(json['pinned_at'] as String).millisecondsSinceEpoch
    : null,
```

改动类型：修改文件，依赖任务 2。

---

## 任务 8：新增依赖 `✅ 已完成`

文件：`client/modules/flash_im_conversation/pubspec.yaml`（修改）

### 8.1 添加 4 个依赖 `✅`

```yaml
flutter_slidable: ^4.0.3        # 移动端滑动操作
fx_env: 0.0.1+3                 # 平台判断 (kApp.isDesktop)
tolyui_feedback: 0.3.6+16       # TolyPopover + showTolyPopPicker
tolyui_feedback_modal: ^0.0.1   # 弹窗组件
```

改动类型：配置变更，无依赖。

---

## 任务 9：ConversationContextMenu `✅ 已完成`

文件：`client/modules/flash_im_conversation/lib/src/view/conversation_context_menu.dart`（新建）

### 9.1 组件结构 `✅`

```dart
class ConversationContextMenu extends StatelessWidget {
  final Conversation conv;
  final void Function(ConversationMenuAction)? onAction;
  final void Function()? onClose;
}
```

### 9.2 UI 样式 `✅`

- 白底圆角竖向列表菜单（与消息右键菜单风格一致）
- 分隔线分隔：基本操作 | 标记操作 | 危险操作
- 每项显示图标 + 文案（通过 `actionInfo` 获取）
- 最大宽度 180px

### 9.3 交互 `✅`

点击菜单项 → `onAction(action)` → 菜单自动关闭。

改动类型：新建文件，依赖任务 5。

---

## 任务 10：ConversationDeleteDialog `✅ 已完成`

文件：`client/modules/flash_im_conversation/lib/src/view/conversation_delete_dialog.dart`（新建）

### 10.1 `showDeleteConfirm()` `✅`

```dart
Future<bool> showDeleteConfirm(BuildContext context, Conversation conv) async {
  // showTolyPopPicker → 确认/取消 → 返回 bool
}
```

### 10.2 `showClearAllConfirm()` `✅`

```dart
Future<bool> showClearAllConfirm(BuildContext context) async {
  // showTolyPopPicker → 确认/取消 → 返回 bool
}
```

### 10.3 样式 `✅`

- 移动端：底部 BottomSheet
- 桌面端：居中 Dialog
- 删除按钮红色突出警告

改动类型：新建文件，依赖任务 9（复用 tolyui_feedback）。

---

## 任务 11：ConversationTile 集成交互 `✅ 已完成`

文件：`client/modules/flash_im_conversation/lib/src/view/conversation_tile.dart`（修改）

### 11.1 移动端：Slidable 滑动菜单 `✅`

```dart
// _buildMobileTile:
Slidable(
  key: ValueKey('slide_${conversation.id}'),
  endActionPane: ActionPane(
    motion: BehindMotion(),
    children: actions.map(_buildSlideActionButton).toList(),
  ),
  child: GestureDetector(
    onLongPressStart: (_) => _showMobileMenu(context),
    child: tile,
  ),
)
```

### 11.2 移动端：长按 BottomSheet `✅`

```dart
void _showMobileMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (_) => _buildBottomSheetMenu(),
  );
}
```

### 11.3 桌面端：TolyPopover 右键菜单 `✅`

```dart
// _buildDesktopTile:
GestureDetector(
  onSecondaryTapUp: (details) {
    ctrl.open(position: details.globalPosition);
  },
  child: TolyPopover(
    controller: ctrl,
    popover: ConversationContextMenu(
      conv: conversation,
      onAction: (action) { ctrl.close(); _handleAction(context, action); },
    ),
    child: tile,
  ),
)
```

### 11.4 统一动作分发 `_handleAction` `✅`

```dart
void _handleAction(BuildContext context, ConversationMenuAction action) {
  switch (action) {
    case pin → cubit.togglePin(id);
    case mute → cubit.toggleMute(id);
    case markRead → cubit.clearUnread(id);
    case markUnread → cubit.markUnread(id);
    case delete → showDeleteConfirm(context, conv).then(...);
    case clearAll → showClearAllConfirm(context).then(...);
  }
}
```

### 11.5 静音图标显示 `✅`

`isMuted` 时在 Tile 上叠加静音铃铛图标。

改动类型：修改文件，依赖任务 5、9、10。

---

## 任务 12：ConversationListPage 分区渲染 `✅ 已完成`

文件：`client/modules/flash_im_conversation/lib/src/view/conversation_list_page.dart`（修改）

### 12.1 分区逻辑 `✅`

```dart
final pinned = conversations.where((c) => c.isPinned).toList();
final normal = conversations.where((c) => !c.isPinned).toList();
```

排序已在 Cubit 层完成（`_sortWithPinned`），此处仅分区展示。

### 12.2 置顶区 Section Header `✅`

灰底 + "置顶" 标题 + 分隔线。

### 12.3 普通区 Section Header `✅`

仅当置顶区非空时显示分隔线。

### 12.4 传递操作回调 `✅`

`ConversationListPage` 不直接处理操作，通过 `ConversationTile` 的 `onAction` 回调向上传递到 cubit。

改动类型：修改文件，依赖任务 6、11。

---

## 任务 13：dart analyze `✅ 已完成`

```bash
dart analyze client/modules/flash_im_conversation/lib/
```

零错误。

---

## 全局约束

- 状态管理：Cubit（flutter_bloc），不使用 Event 模式
- 乐观更新：toggle 操作先更新 UI 再发 HTTP，失败回滚
- 平台判断：`fx_env` 的 `kApp.isDesktop`，不直接 import `dart:io`
- 弹窗风格：统一使用 `showTolyPopPicker`（移动端 BottomSheet / 桌面端 Dialog）
- 右键菜单：统一使用 `TolyPopover`（来自 `tolyui_feedback`）
- 样式参考：消息右键菜单实现（`flash_im_chat/lib/src/view/menu/`）
