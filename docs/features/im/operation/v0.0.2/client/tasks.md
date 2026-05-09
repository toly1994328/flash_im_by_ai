# 消息转发与@提及与置顶 — 客户端任务清单

基于 [design.md](design.md) 设计。改动分布在 flash_im_chat、flash_im_core、flash_im_conversation。

---

## 执行顺序

### 阶段一：基础设施

1. ⬜ 任务 1 — WsClient 扩展（pinChangedStream）
2. ⬜ 任务 2 — MessageRepository 扩展（转发/置顶 API）
3. ⬜ 任务 3 — ChatState 扩展（pinnedMessages）

### 阶段二：转发功能

4. ⬜ 任务 4 — ConversationPickerPage（会话选择器）
5. ⬜ 任务 5 — ChatCubit 转发逻辑
6. ⬜ 任务 6 — ForwardBubble + ForwardDetailPage（合并转发展示）

### 阶段三：@提及功能

7. ⬜ 任务 7 — MentionPicker（成员选择浮层）
8. ⬜ 任务 8 — ChatInput @检测 + mentions 构建
9. ⬜ 任务 9 — TextBubble @高亮渲染
10. ⬜ 任务 10 — 会话列表@提示标识

### 阶段四：置顶功能

11. ⬜ 任务 11 — PinnedMessageBar（置顶消息栏）
12. ⬜ 任务 12 — ChatCubit 置顶逻辑 + PIN_CHANGED 监听

### 阶段五：集成

13. ⬜ 任务 13 — MessageActionMenu 扩展（转发/置顶菜单项）
14. ⬜ 任务 14 — 多选模式扩展（转发按钮）
15. ⬜ 任务 15 — flutter analyze

---

## 任务 1：WsClient 扩展 `⬜`

文件：`client/modules/flash_im_core/lib/src/logic/ws_client.dart`（修改）

### 1.1 新增 pinChangedStream `⬜`

```dart
final _pinChangedController = StreamController<WsFrame>.broadcast();
Stream<WsFrame> get pinChangedStream => _pinChangedController.stream;
```

### 1.2 switch 分发新增 PIN_CHANGED `⬜`

```dart
case WsFrameType.PIN_CHANGED:
  _pinChangedController.add(frame);
```

### 1.3 dispose 关闭 controller `⬜`

---

## 任务 2：MessageRepository 扩展 `⬜`

文件：`client/modules/flash_im_chat/lib/src/data/message_repository.dart`（修改）

### 2.1 forwardMessage `⬜`

```dart
Future<Map<String, dynamic>> forwardMessage({
  required String sourceConvId,
  required List<String> messageIds,
  required String targetConvId,
  required String forwardType, // "single" | "merge"
}) async {
  final res = await _dio.post('/conversations/$sourceConvId/messages/forward', data: {
    'message_ids': messageIds,
    'target_conversation_id': targetConvId,
    'forward_type': forwardType,
  });
  return res.data as Map<String, dynamic>;
}
```

### 2.2 pinMessage `⬜`

```dart
Future<Map<String, dynamic>> pinMessage(String convId, String messageId) async {
  final res = await _dio.post('/conversations/$convId/messages/pin', data: {
    'message_id': messageId,
  });
  return res.data as Map<String, dynamic>;
}
```

### 2.3 unpinMessage `⬜`

```dart
Future<void> unpinMessage(String convId, String pinId) async {
  await _dio.delete('/conversations/$convId/messages/pin/$pinId');
}
```

### 2.4 getPinnedMessages `⬜`

```dart
Future<List<Map<String, dynamic>>> getPinnedMessages(String convId) async {
  final res = await _dio.get('/conversations/$convId/messages/pinned');
  return (res.data as List).cast<Map<String, dynamic>>();
}
```

---

## 任务 3：ChatState 扩展 `⬜`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_state.dart`（修改）

### 3.1 ChatLoaded 新增 pinnedMessages `⬜`

```dart
class ChatLoaded extends ChatState {
  // ... 已有字段
  final List<PinnedMessage> pinnedMessages;
  // copyWith 新增对应参数
}
```

### 3.2 PinnedMessage 模型 `⬜`

文件：`client/modules/flash_im_chat/lib/src/data/message.dart`（修改）

```dart
class PinnedMessage {
  final String pinId;
  final String messageId;
  final String content;
  final int msgType;
  final String senderName;
  final int pinnedBy;
  final DateTime pinnedAt;

  factory PinnedMessage.fromJson(Map<String, dynamic> json) => ...;
}
```

### 3.3 MessageType 新增 forward `⬜`

```dart
enum MessageType { text, image, video, file, forward }
```

对应 msg_type=5。MessageBubble 的 switch 新增 forward 分支。

---

## 任务 4：ConversationPickerPage `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/conversation_picker_page.dart`（新建）

独立页面，展示最近会话 + 好友列表，选择后返回目标会话 ID。

```dart
class ConversationPickerPage extends StatefulWidget {
  final String? excludeConvId; // 排除当前会话

  // 返回值：选中的 conversation_id
}
```

### 4.1 页面结构 `⬜`

- AppBar：白色，标题"选择会话"
- 搜索栏：FlashSearchBar（editable）
- 最近会话列表：通过 ConversationRepository（已注入到 ChatPage 的 context）获取
- 好友列表：通过 FriendCubit（已在 home_page 注册）获取
- 点击某项 → 弹确认弹窗 → Navigator.pop(conversationId)

### 4.2 确认弹窗 `⬜`

```dart
showTolyPopPicker(
  title: Text('转发给 $name？'),
  tasks: [TolyMenuItem(info: '确认', task: () => ...)],
)
```

---

## 任务 5：ChatCubit 转发逻辑 `⬜`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_cubit.dart`（修改）

### 5.1 forwardMessages `⬜`

```dart
Future<void> forwardMessages({
  required List<String> messageIds,
  required String targetConvId,
  required String forwardType,
}) async {
  await _repository.forwardMessage(
    sourceConvId: conversationId,
    messageIds: messageIds,
    targetConvId: targetConvId,
    forwardType: forwardType,
  );
}
```

转发成功后不需要刷新当前会话（消息发到了目标会话），显示 SnackBar "已转发"。

### 5.2 sendMessage 扩展支持 mentions `⬜`

```dart
void sendMessage(String content, {List<Map<String, dynamic>>? mentions}) {
  // 已有逻辑...
  // 如果 mentions 不为空，合并到 extra 里
  if (mentions != null && mentions.isNotEmpty) {
    extra = (extra ?? {})..['mentions'] = mentions;
  }
}
```

---

## 任务 6：ForwardBubble + ForwardDetailPage `⬜`

### 6.1 ForwardBubble `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/bubble/forward_bubble.dart`（新建）

合并转发消息的卡片展示：

```dart
class ForwardBubble extends StatelessWidget {
  final Message message; // type=5, extra 含 forward_messages
  final VoidCallback? onTap;

  // 渲染：白色卡片 + 标题 + 前 3 条消息摘要 + "查看 N 条聊天记录"
}
```

样式：白色圆角卡片，边框 #E0E0E0，内部显示标题 + 前 3 条消息的 sender_name: content 摘要。

### 6.2 ForwardDetailPage `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/forward_detail_page.dart`（新建）

展开合并转发的原始消息列表（只读）：

```dart
class ForwardDetailPage extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> messages; // extra.forward_messages

  // ListView 展示每条消息：头像 + 名字 + 内容 + 时间
}
```

### 6.3 MessageBubble 集成 `⬜`

在 `_buildBubble()` 的 switch 里新增 `MessageType.forward` 分支，渲染 ForwardBubble。

---

## 任务 7：MentionPicker `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/mention_picker.dart`（新建）

@成员选择浮层，在输入框上方弹出：

```dart
class MentionPicker extends StatelessWidget {
  final List<GroupMember> members;
  final bool isOwnerOrAdmin; // 是否显示"所有人"选项
  final void Function(String userId, String nickname) onSelect;
  final VoidCallback onDismiss;
}
```

### 7.1 样式 `⬜`

- 白色圆角卡片，阴影，最大高度 200px
- 列表项：头像 32px + 昵称
- 第一项（如果 isOwnerOrAdmin）："所有人"
- 支持搜索过滤

---

## 任务 8：ChatInput @检测 + mentions 构建 `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/chat_input.dart`（修改）

### 8.1 @字符检测 `⬜`

监听 TextEditingController 变化，检测新输入的字符是否为 `@`：

```dart
void _onTextChanged() {
  final text = _controller.text;
  final selection = _controller.selection;
  if (selection.baseOffset > 0) {
    final lastChar = text[selection.baseOffset - 1];
    if (lastChar == '@' && widget.isGroup) {
      _showMentionPicker();
    }
  }
}
```

### 8.2 选择后插入文本 `⬜`

选择成员后，在 @ 位置插入 `昵称 `（带空格），记录 MentionInfo（userId, offset, length）到列表。

### 8.3 发送时构建 extra.mentions `⬜`

发送消息时，将 mentions 列表转为 JSON 数组传给 ChatCubit：

```dart
final mentions = _mentionInfos.map((m) => {
  'user_id': m.userId,
  'offset': m.offset,
  'length': m.length,
}).toList();
```

### 8.4 新增参数 `⬜`

```dart
class ChatInput extends StatefulWidget {
  // ... 已有参数
  final bool isGroup;
  final List<GroupMember>? groupMembers;
  final bool isOwnerOrAdmin;
  final void Function(String content, List<Map<String, dynamic>>? mentions)? onSendWithMentions;
}
```

---

## 任务 9：TextBubble @高亮渲染 `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/bubble/text_bubble.dart`（修改）

### 9.1 解析 mentions 构建 TextSpan `⬜`

```dart
Widget _buildRichText(String content, List<MentionInfo>? mentions) {
  if (mentions == null || mentions.isEmpty) {
    return Text(content, style: ...);
  }
  // 按 offset 排序，分段构建 TextSpan
  // 普通文本：黑色
  // @文本：蓝色 #3B82F6 + FontWeight.w500
  return RichText(text: TextSpan(children: spans));
}
```

---

## 任务 10：会话列表@提示标识 `⬜`

文件：`client/modules/flash_im_conversation/lib/src/view/conversation_tile.dart`（修改）
文件：`client/modules/flash_im_cache/lib/src/models/cached_conversation.dart`（修改）

### 10.1 CachedConversation 新增 lastMessageExtra 字段 `⬜`

```dart
class CachedConversation {
  // ... 已有字段
  final String? lastMessageExtra; // JSON 字符串，含 mentions 等
}
```

同步修改 drift 表定义、converters、SyncEngine 的 ConversationUpdate 处理。

### 10.2 检测 mentions 显示红色前缀 `⬜`

ConversationUpdate 帧新增了 `last_message_extra` 字段。会话列表 tile 解析该字段，如果 mentions 包含当前用户 ID 或 "all"，在预览文本前显示红色「[有人@我]」。

```dart
// conversation_tile.dart
if (_hasMentionMe(conv.lastMessageExtra, currentUserId)) {
  // 前缀：红色 [有人@我]
}
```

---

## 任务 11：PinnedMessageBar `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/pinned_message_bar.dart`（新建）

ChatPage 顶部的置顶消息栏：

```dart
class PinnedMessageBar extends StatelessWidget {
  final List<PinnedMessage> pinnedMessages;
  final VoidCallback? onClose; // 取消置顶（仅群主可见）
  final bool isOwner;
}
```

### 11.1 样式 `⬜`

- 背景色 #FFF9E6（浅黄），底部 0.5px 边框 #EEE6CC
- 左侧图钉图标 + 消息摘要（单行省略）
- 右侧：群主显示 × 按钮（取消置顶），普通成员不显示
- 多条置顶时显示第一条，可左右滑动切换（或显示数量角标）

---

## 任务 12：ChatCubit 置顶逻辑 `⬜`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_cubit.dart`（修改）

### 12.1 加载置顶列表 `⬜`

```dart
Future<void> loadPinnedMessages() async {
  final data = await _repository.getPinnedMessages(conversationId);
  final pinned = data.map((e) => PinnedMessage.fromJson(e)).toList();
  final s = state;
  if (s is ChatLoaded) emit(s.copyWith(pinnedMessages: pinned));
}
```

在 `loadMessages()` 后调用。

### 12.2 置顶消息 `⬜`

```dart
Future<void> pinMessage(String messageId) async {
  await _repository.pinMessage(conversationId, messageId);
  await loadPinnedMessages(); // 刷新列表
}
```

### 12.3 取消置顶 `⬜`

```dart
Future<void> unpinMessage(String pinId) async {
  await _repository.unpinMessage(conversationId, pinId);
  await loadPinnedMessages();
}
```

### 12.4 监听 PIN_CHANGED `⬜`

```dart
_pinChangedSub = _wsClient.pinChangedStream.listen((frame) {
  final notif = PinChangedNotification.fromBuffer(frame.payload);
  if (notif.conversationId != conversationId) return;
  loadPinnedMessages(); // 实时刷新
});
```

构造函数新增订阅，close() 取消。

---

## 任务 13：MessageActionMenu 扩展 `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/message_action_menu.dart`（修改）

### 13.1 新增 MenuAction.forward 和 MenuAction.pin `⬜`

```dart
enum MenuAction { copy, reply, recall, delete, multiSelect, forward, pin }
```

### 13.2 _getActions 过滤逻辑 `⬜`

```dart
MenuAction.forward, // 所有消息都可转发
if (isGroupOwner && !message.isRecalled) MenuAction.pin, // 仅群主 + 未撤回
```

### 13.3 ChatPage 处理新 action `⬜`

```dart
case MenuAction.forward:
  _openConversationPicker(context, [msg.id], 'single');
case MenuAction.pin:
  chatCubit.pinMessage(msg.id);
```

---

## 任务 14：多选模式扩展 `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/chat_page.dart`（修改）

### 14.1 底部操作栏新增"转发"按钮 `⬜`

多选模式底部操作栏从 [取消 | 已选N条 | 删除] 变为 [取消 | 已选N条 | 转发 | 删除]。

点击"转发" → 打开 ConversationPickerPage → 选择目标 → 调用 forwardMessages（merge 模式）。

---

## 任务 15：flutter analyze `⬜`

```bash
cd client
flutter analyze
```

确保零错误。
