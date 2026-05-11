# 消息置顶 — 客户端任务清单

基于 [design.md](design.md) 设计。改动分布在 flash_im_chat、flash_im_core。

---

## 执行顺序

### 阶段一：基础设施

1. ✅ 任务 1 — WsClient 扩展（pinChangedStream）
2. ✅ 任务 2 — MessageRepository 扩展（pin/unpin/getPinned）
3. ✅ 任务 3 — ChatState 扩展（pinnedMessages）+ PinnedMessage 模型

### 阶段二：置顶功能

4. ✅ 任务 4 — PinnedMessageBar（置顶消息栏 + SizeTransition 动画）
5. ✅ 任务 5 — ChatCubit 置顶逻辑 + PIN_CHANGED 监听
6. ✅ 任务 6 — MessageActionMenu 扩展（pin/unpin 菜单项）

### 阶段三：验证

7. ✅ 任务 7 — flutter analyze

---

## 任务 1：WsClient 扩展 `✅`

文件：`client/modules/flash_im_core/lib/src/logic/ws_client.dart`（修改）

### 1.1 新增 pinChangedStream `✅`

```dart
final _pinChangedController = StreamController<WsFrame>.broadcast();
Stream<WsFrame> get pinChangedStream => _pinChangedController.stream;
```

### 1.2 switch 分发新增 PIN_CHANGED `✅`

```dart
case WsFrameType.PIN_CHANGED:
  _pinChangedController.add(frame);
```

### 1.3 dispose 关闭 controller `✅`

---

## 任务 2：MessageRepository 扩展 `✅`

文件：`client/modules/flash_im_chat/lib/src/data/message_repository.dart`（修改）

### 2.1 pinMessage `✅`

```dart
Future<Map<String, dynamic>> pinMessage(String convId, String messageId) async {
  final res = await _dio.post('/conversations/$convId/messages/pin', data: {
    'message_id': messageId,
  });
  return res.data as Map<String, dynamic>;
}
```

### 2.2 unpinMessage `✅`

```dart
Future<void> unpinMessage(String convId, String pinId) async {
  await _dio.delete('/conversations/$convId/messages/pin/$pinId');
}
```

### 2.3 getPinnedMessages `✅`

```dart
Future<List<Map<String, dynamic>>> getPinnedMessages(String convId) async {
  final res = await _dio.get('/conversations/$convId/messages/pinned');
  return (res.data as List).cast<Map<String, dynamic>>();
}
```

---

## 任务 3：ChatState 扩展 + PinnedMessage 模型 `✅`

### 3.1 PinnedMessage 模型 `✅`

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

### 3.2 ChatLoaded 新增 pinnedMessages `✅`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_state.dart`（修改）

```dart
class ChatLoaded extends ChatState {
  final List<PinnedMessage> pinnedMessages;
  // copyWith 新增对应参数
}
```

---

## 任务 4：PinnedMessageBar `✅`

文件：`client/modules/flash_im_chat/lib/src/view/pinned_message_bar.dart`（新建）

### 4.1 组件结构 `✅`

```dart
class PinnedMessageBar extends StatefulWidget {
  final List<PinnedMessage> pinnedMessages;
  final bool isOwner;
  final void Function(String pinId)? onUnpin;
}
```

### 4.2 样式 `✅`

- 收起状态：浅灰背景 + 图钉图标 + 第一条消息摘要 + 展开箭头
- 展开状态：SizeTransition 动画 + 所有置顶消息列表 + 每条可取消
- 底部下圆角

### 4.3 SizeTransition 动画 `✅`

```dart
AnimationController _animController;
Animation<double> _animation;
// 点击切换 forward/reverse
```

---

## 任务 5：ChatCubit 置顶逻辑 `✅`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_cubit.dart`（修改）

### 5.1 加载置顶列表 `✅`

```dart
Future<void> loadPinnedMessages() async {
  final data = await _repository.getPinnedMessages(conversationId);
  final pinned = data.map((e) => PinnedMessage.fromJson(e)).toList();
  // emit 更新 state
}
```

### 5.2 置顶/取消置顶 `✅`

```dart
Future<void> pinMessage(String messageId) async {
  await _repository.pinMessage(conversationId, messageId);
  await loadPinnedMessages();
}

Future<void> unpinMessage(String pinId) async {
  await _repository.unpinMessage(conversationId, pinId);
  await loadPinnedMessages();
}
```

### 5.3 监听 PIN_CHANGED `✅`

```dart
_pinChangedSub = _wsClient.pinChangedStream.listen((frame) {
  final notif = PinChangedNotification.fromBuffer(frame.payload);
  if (notif.conversationId != conversationId) return;
  loadPinnedMessages();
});
```

---

## 任务 6：MessageActionMenu 扩展 `✅`

文件：`client/modules/flash_im_chat/lib/src/view/message_action_menu.dart`（修改）

### 6.1 新增 MenuAction.pin 和 MenuAction.unpin `✅`

```dart
enum MenuAction { ..., pin, unpin }
```

### 6.2 _getActions 过滤逻辑 `✅`

- 群聊 + 未撤回 + 未置顶 → 显示"置顶"
- 群聊 + 已置顶 → 显示"取消"

### 6.3 ChatPage 处理 `✅`

```dart
case MenuAction.pin:
  chatCubit.pinMessage(msg.id);
case MenuAction.unpin:
  final pinId = _getPinId(msg.id);
  if (pinId != null) chatCubit.unpinMessage(pinId);
```

---

## 任务 7：flutter analyze `✅`

```bash
cd client
flutter analyze
```

确保零错误。
