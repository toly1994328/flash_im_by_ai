# IM Core v0.0.3 — 客户端任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。
三层架构：data / logic / view，与其他模块保持一致。
参考项目：`docs/ref/flash_im-main/app/packages/im_chat/`

---

## 执行顺序

1. ⬜ 任务 1 — WsClient 帧分发扩展（flash_im_core 修改）
2. ⬜ 任务 2 — 创建 flash_im_chat 模块骨架
3. ⬜ 任务 3 — Message 数据模型
4. ⬜ 任务 4 — MessageRepository（HTTP 历史消息）
5. ⬜ 任务 5 — ChatCubit + ChatState
6. ⬜ 任务 6 — MessageBubble 组件
7. ⬜ 任务 7 — ChatInput 组件
8. ⬜ 任务 8 — ChatPage 页面
9. ⬜ 任务 9 — barrel 导出
10. ⬜ 任务 10 — 主工程集成（路由 + 会话列表 onTap）
11. ⬜ 任务 11 — ConversationListCubit 扩展（CONVERSATION_UPDATE 监听 + total_unread）
12. ⬜ 任务 12 — 底部导航角标（total_unread）
13. ⬜ 任务 13 — 编译验证 + 功能验证

---

## 任务 1：WsClient 帧分发扩展 `⬜`

文件：`client/modules/flash_im_core/lib/src/logic/ws_client.dart`（修改）

### 1.1 新增 proto 导入 `⬜`

导入 message.proto 生成的 Dart 代码（ChatMessage、MessageAck、ConversationUpdate 等）。
需要先运行 proto 代码生成脚本。

### 1.2 新增分类型 StreamController `⬜`

```dart
final _chatMessageController = StreamController<WsFrame>.broadcast();
final _messageAckController = StreamController<WsFrame>.broadcast();
final _conversationUpdateController = StreamController<WsFrame>.broadcast();

Stream<WsFrame> get chatMessageStream => _chatMessageController.stream;
Stream<WsFrame> get messageAckStream => _messageAckController.stream;
Stream<WsFrame> get conversationUpdateStream => _conversationUpdateController.stream;
```

### 1.3 修改 _onData 帧分发 `⬜`

在已认证阶段，按 frame.type 分发到对应 StreamController：

```dart
// 已认证：按类型分发
switch (frame.type) {
  case WsFrameType.PONG:
    _missedPongs = 0;
    return;
  case WsFrameType.CHAT_MESSAGE:
    _chatMessageController.add(frame);
  case WsFrameType.MESSAGE_ACK:
    _messageAckController.add(frame);
  case WsFrameType.CONVERSATION_UPDATE:
    _conversationUpdateController.add(frame);
  default:
    break;
}
_frameController.add(frame); // 保留原始帧流
```

### 1.4 dispose 中关闭新增 StreamController `⬜`

### 1.5 新增 sendMessage 便捷方法 `⬜`

```dart
/// 发送聊天消息
void sendMessage({
  required String conversationId,
  required String content,
  String? clientId,
}) {
  final req = SendMessageRequest()
    ..conversationId = conversationId
    ..type = MessageType.TEXT
    ..content = content
    ..clientId = clientId ?? '';
  final frame = WsFrame()
    ..type = WsFrameType.CHAT_MESSAGE
    ..payload = req.writeToBuffer();
  sendFrame(frame);
}
```

---

## 任务 2：创建 flash_im_chat 模块骨架 `⬜`

### 2.1 flutter create `⬜`

```powershell
cd client/modules
flutter create --template=package --project-name=flash_im_chat flash_im_chat
```

### 2.2 添加依赖 `⬜`

文件：`client/modules/flash_im_chat/pubspec.yaml`（修改）

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.8.0+1
  flutter_bloc: ^8.1.6
  equatable: ^2.0.7
  shimmer: ^3.0.0
  flash_im_core:
    path: ../flash_im_core
```

### 2.3 三层目录结构 `⬜`

```
lib/src/
├── data/
│   ├── message.dart
│   └── message_repository.dart
├── logic/
│   ├── chat_cubit.dart
│   └── chat_state.dart
└── view/
    ├── chat_page.dart
    ├── message_bubble.dart
    └── chat_input.dart
```

---

## 任务 3：Message 数据模型 `⬜`

文件：`client/modules/flash_im_chat/lib/src/data/message.dart`（新建）

```dart
enum MessageStatus { sending, sent, failed }

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final int seq;
  final String content;
  final MessageStatus status;
  final DateTime createdAt;

  // fromJson（HTTP 历史消息）
  // fromProto（WebSocket ChatMessage 帧）
  // sending() 工厂方法（本地乐观更新）
  // copyWith（更新状态）
}
```

---

## 任务 4：MessageRepository `⬜`

文件：`client/modules/flash_im_chat/lib/src/data/message_repository.dart`（新建）

```dart
class MessageRepository {
  final Dio _dio;

  /// 获取历史消息
  Future<List<Message>> getMessages(String conversationId, {int? beforeSeq, int limit = 50}) async
  // GET /conversations/:id/messages?before_seq=&limit=
}
```

---

## 任务 5：ChatCubit + ChatState `⬜`

### 5.1 ChatState `⬜`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_state.dart`（新建）

```dart
sealed class ChatState extends Equatable { ... }
class ChatInitial extends ChatState { ... }
class ChatLoading extends ChatState { ... }
class ChatLoaded extends ChatState {
  final List<Message> messages;
  final bool hasMore;
  final bool isLoadingMore;
}
class ChatError extends ChatState { final String message; }
```

### 5.2 ChatCubit `⬜`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_cubit.dart`（新建）

```dart
class ChatCubit extends Cubit<ChatState> {
  final MessageRepository _repository;
  final WsClient _wsClient;
  final String conversationId;
  final String currentUserId;

  StreamSubscription? _chatMessageSub;
  StreamSubscription? _messageAckSub;
  final Map<String, String> _pendingMessages = {}; // clientId -> localId

  // loadMessages() — HTTP 加载历史，emit Loading → Loaded
  // loadMore() — 基于 before_seq 加载更早消息
  // sendMessage(content) — 乐观更新 + WS 发送 + 超时处理
  // _handleIncomingMessage(frame) — 解析 ChatMessage，过滤当前会话，追加列表
  // _handleMessageAck(frame) — 匹配 pending，更新 status=sent，填入 id/seq
  // dispose() — 取消订阅
}
```

关键逻辑：
- loadMessages: emit ChatLoading → repo.getMessages → emit ChatLoaded
- sendMessage: 生成 localId + clientId → 创建 Message.sending() → emit 追加 → wsClient.sendMessage → 10s 超时标记 failed
- _handleIncomingMessage: 只处理当前会话、跳过自己发的、去重、按 seq 排序
- _handleMessageAck: 取 _pendingMessages 第一个匹配、更新 id/seq/status

---

## 任务 6：MessageBubble 组件 `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/message_bubble.dart`（新建）

```dart
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  // 布局：
  // isMe=true: 靠右，蓝色背景，白色文字
  // isMe=false: 靠左，灰色背景，黑色文字
  // 气泡内：content 文字
  // 气泡外下方：时间（HH:mm）
  // status=sending: 小时钟图标
  // status=failed: 红色感叹号
}
```

---

## 任务 7：ChatInput 组件 `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/chat_input.dart`（新建）

```dart
class ChatInput extends StatefulWidget {
  final ValueChanged<String> onSend;

  // 布局：
  // Row [ TextField(Expanded) + 发送按钮 ]
  // 发送按钮：内容为空时禁用
  // 发送后清空输入框
  // 底部安全区域适配
}
```

---

## 任务 8：ChatPage 页面 `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/chat_page.dart`（新建）

```dart
class ChatPage extends StatelessWidget {
  final String conversationId;
  final String peerName;
  final String? peerAvatar;

  // AppBar: 对方昵称 + 返回按钮
  // Body:
  //   ChatLoading → 骨架屏（Shimmer 模拟消息气泡）
  //   ChatError → 错误提示 + 重试
  //   ChatLoaded → ListView.builder(reverse: true) + MessageBubble
  //     - 滚动到顶部触发 loadMore
  //     - hasMore 时顶部显示 loading 指示器
  // BottomBar: ChatInput
  //   - onSend → cubit.sendMessage(content)
}
```

---

## 任务 9：barrel 导出 `⬜`

文件：`client/modules/flash_im_chat/lib/flash_im_chat.dart`（修改）

```dart
export 'src/data/message.dart';
export 'src/data/message_repository.dart';
export 'src/logic/chat_cubit.dart';
export 'src/logic/chat_state.dart';
export 'src/view/chat_page.dart';
export 'src/view/message_bubble.dart';
export 'src/view/chat_input.dart';
```

---

## 任务 10：主工程集成 `⬜`

### 10.1 pubspec.yaml 注册模块 `⬜`

文件：`client/pubspec.yaml`（修改）

```yaml
  flash_im_chat:
    path: modules/flash_im_chat
```

### 10.2 main.dart 注入 Repository `⬜`

文件：`client/lib/main.dart`（修改）

```dart
final messageRepo = MessageRepository(dio: httpClient.dio);
// 通过 RepositoryProvider 传递
RepositoryProvider.value(value: messageRepo),
```

### 10.3 会话列表 onTap 导航到聊天页 `⬜`

文件：`client/modules/flash_im_conversation/lib/src/view/conversation_list_page.dart`（修改）

ConversationTile 的 onTap 改为导航到 ChatPage：

```dart
onTap: () {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => BlocProvider(
      create: (_) => ChatCubit(
        repository: context.read<MessageRepository>(),
        wsClient: context.read<WsClient>(),
        conversationId: conversation.id,
        currentUserId: currentUser.userId.toString(),
      )..loadMessages(),
      child: ChatPage(
        conversationId: conversation.id,
        peerName: conversation.displayName,
        peerAvatar: conversation.displayAvatar,
      ),
    ),
  ));
},
```

---

## 任务 11：ConversationListCubit 扩展 `⬜`

文件：`client/modules/flash_im_conversation/lib/src/logic/conversation_list_cubit.dart`（修改）

### 11.1 监听 conversationUpdateStream `⬜`

构造函数中订阅 WsClient.conversationUpdateStream：

```dart
_updateSub = wsClient.conversationUpdateStream.listen(_handleConversationUpdate);
```

### 11.2 _handleConversationUpdate 方法 `⬜`

```dart
void _handleConversationUpdate(WsFrame frame) {
  // 1. 解析 ConversationUpdate
  // 2. 在当前列表中找到对应 conversation_id
  // 3. 更新 lastMessagePreview、lastMessageAt、unreadCount
  // 4. 重新排序（按 lastMessageAt 倒序）
  // 5. 更新 totalUnread
  // 6. emit 新状态
}
```

### 11.3 totalUnread 字段 `⬜`

ConversationListLoaded 状态新增 `int totalUnread` 字段，从 CONVERSATION_UPDATE 帧的 total_unread 取值。

### 11.4 dispose 取消订阅 `⬜`

---

## 任务 12：底部导航角标 `⬜`

文件：`client/lib/src/home/view/home_page.dart`（修改）

在消息 Tab 的 BottomNavigationBarItem 上显示未读角标：

```dart
// 从 ConversationListCubit 的 state 中取 totalUnread
// totalUnread > 0 时在图标右上角显示红色圆点或数字
// totalUnread > 99 显示 "99+"
```

---

## 任务 13：编译验证 + 功能验证 `⬜`

### 13.1 编译 `⬜`

```powershell
cd client
flutter pub get
flutter analyze
```

### 13.2 功能验证 `⬜`

1. 重置数据库 + 种子数据
2. 启动后端
3. 启动客户端
4. 用朱红登录，点击会话列表中的橘橙
5. 聊天页显示骨架屏 → 加载完成显示历史消息（如果有）
6. 输入文字发送，消息立刻出现（sending 状态）
7. 收到 ACK 后状态变为 sent
8. 用另一台设备登录橘橙，验证实时收到消息
9. 返回会话列表，验证预览和时间已更新
10. 底部导航角标显示总未读数
