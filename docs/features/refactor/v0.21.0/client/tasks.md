# IM 测试基础设施 + ChatCubit 拆分 — 客户端任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。

全局约束：
- 测试框架：flutter_test + bloc_test + mocktail
- mock 不使用代码生成，手动编写或 mocktail 自动 mock
- Mixin 通过抽象 getter 访问 Cubit 字段，不暴露私有成员
- 所有测试文件放在 `flash_im_chat/test/` 下

---

## 执行顺序

1. ⬜ 任务 1 — 添加测试依赖（无依赖）
2. ⬜ 任务 2 — 抽取 IMessageRepository 接口（无依赖）
3. ⬜ 任务 3 — MessageRepository 实现接口（依赖任务 2）
4. ⬜ 任务 4 — ChatCubit 改为依赖接口（依赖任务 2）
5. ⬜ 任务 5 — 创建 FakeWsClient（无依赖）
6. ⬜ 任务 6 — 创建 MockLocalStore（无依赖）
7. ⬜ 任务 7 — 创建 MockMessageRepository（依赖任务 2）
8. ⬜ 任务 8 — 创建 TestFixtures（依赖任务 2）
9. ⬜ 任务 9 — 编写 ChatCubit 单元测试（依赖任务 4-8）
10. ⬜ 任务 10 — 拆分 ChatFileMixin（依赖任务 9 全部通过）
11. ⬜ 任务 11 — 拆分 ChatPinMixin（依赖任务 10）
12. ⬜ 任务 12 — 拆分 ChatSelectMixin（依赖任务 11）
13. ⬜ 任务 13 — 编译验证 + 测试验证

---

## 任务 1：pubspec.yaml — 添加测试依赖 `⬜ 待处理`

文件：`client/modules/flash_im_chat/pubspec.yaml`

### 1.1 添加 dev_dependencies `⬜`

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
```

---

## 任务 2：i_message_repository.dart — 抽取抽象接口 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/data/i_message_repository.dart`（新建）

### 2.1 定义接口 `⬜`

从当前 `MessageRepository` 的公开方法提取抽象接口：

```dart
import 'package:flash_im_cache/flash_im_cache.dart';
import 'message.dart';
import 'message_repository.dart'; // ImageUploadResult 等类型

abstract class IMessageRepository {
  Future<List<Message>> getMessages(String conversationId, {int? beforeSeq, int limit});
  Future<ImageUploadResult> uploadImage(String filePath, {void Function(double)? onProgress});
  Future<VideoUploadResult> uploadVideo(String filePath, String thumbPath, int durationMs, {int width, int height, void Function(double)? onProgress});
  Future<FileUploadResult> uploadFile(String filePath, {void Function(double)? onProgress});
  Future<void> downloadFile(String url, String savePath, {void Function(double)? onProgress});
  Future<void> recallMessage(String conversationId, String messageId);
  Future<void> forwardMessage({required String sourceConvId, required List<String> messageIds, required String targetConvId, required String forwardType});
  Future<List<Map<String, dynamic>>> getPinnedMessages(String conversationId);
  Future<void> pinMessage(String conversationId, String messageId);
  Future<void> unpinMessage(String conversationId, String pinId);
  Future<Map<String, int>> getReadSeq(String conversationId);
  LocalStore? get store;
}
```

### 2.2 导出接口 `⬜`

在 `flash_im_chat` 的 barrel file 中导出 `i_message_repository.dart`。

---

## 任务 3：message_repository.dart — 实现接口 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/data/message_repository.dart`（修改）

### 3.1 添加 implements `⬜`

```dart
class MessageRepository implements IMessageRepository {
  // 现有代码不变，只加 implements 声明
}
```

确保所有公开方法签名与接口一致。如有不一致（如参数名、默认值），以接口为准调整。

---

## 任务 4：chat_cubit.dart — 依赖接口 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_cubit.dart`（修改）

### 4.1 字段类型改为接口 `⬜`

```dart
// 改前
final MessageRepository _repository;

// 改后
final IMessageRepository _repository;
```

### 4.2 构造函数参数类型改为接口 `⬜`

```dart
ChatCubit({
  required IMessageRepository repository,  // 改为接口类型
  // ...
})
```

### 4.3 确认编译通过 `⬜`

`flutter analyze` 零 error。

---

## 任务 5：fake_ws_client.dart — 创建测试用 WsClient `⬜ 待处理`

文件：`client/modules/flash_im_chat/test/mocks/fake_ws_client.dart`（新建）

### 5.1 实现 FakeWsClient `⬜`

暴露 StreamController，测试代码可精确控制事件时序：

```dart
import 'dart:async';
import 'package:flash_im_core/flash_im_core.dart';

class FakeWsClient extends WsClient {
  final chatMessageController = StreamController<WsFrame>.broadcast();
  final messageAckController = StreamController<WsFrame>.broadcast();
  final messageRecalledController = StreamController<WsFrame>.broadcast();
  final pinChangedController = StreamController<WsFrame>.broadcast();
  final readReceiptController = StreamController<WsFrame>.broadcast();

  // 记录发送的消息，供断言验证
  final List<SendMessageCall> sentMessages = [];

  FakeWsClient() : super(config: ImConfig(wsUrl: ''), tokenProvider: () => null);

  @override
  Stream<WsFrame> get chatMessageStream => chatMessageController.stream;
  @override
  Stream<WsFrame> get messageAckStream => messageAckController.stream;
  @override
  Stream<WsFrame> get messageRecalledStream => messageRecalledController.stream;
  @override
  Stream<WsFrame> get pinChangedStream => pinChangedController.stream;
  @override
  Stream<WsFrame> get readReceiptStream => readReceiptController.stream;

  @override
  void sendMessage({required String conversationId, required String content, ...}) {
    sentMessages.add(SendMessageCall(conversationId: conversationId, content: content, ...));
  }

  void dispose() {
    chatMessageController.close();
    messageAckController.close();
    messageRecalledController.close();
    pinChangedController.close();
    readReceiptController.close();
  }
}

class SendMessageCall {
  final String conversationId;
  final String content;
  // ... 其他参数
}
```

注意：需要确认 WsClient 的 stream getter 和 sendMessage 是否可 override。如果不可以，需要为 WsClient 也抽接口或改为非 final。

---

## 任务 6：mock_local_store.dart — 创建 Mock `⬜ 待处理`

文件：`client/modules/flash_im_chat/test/mocks/mock_local_store.dart`（新建）

### 6.1 用 mocktail 生成 `⬜`

```dart
import 'package:flash_im_cache/flash_im_cache.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalStore extends Mock implements LocalStore {}
```

LocalStore 已是抽象类，mocktail 可直接 mock。

---

## 任务 7：mock_message_repository.dart — 创建 Mock `⬜ 待处理`

文件：`client/modules/flash_im_chat/test/mocks/mock_message_repository.dart`（新建）

### 7.1 用 mocktail 生成 `⬜`

```dart
import 'package:flash_im_chat/src/data/i_message_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements IMessageRepository {}
```

---

## 任务 8：test_fixtures.dart — 测试数据工厂 `⬜ 待处理`

文件：`client/modules/flash_im_chat/test/fixtures/test_fixtures.dart`（新建）

### 8.1 Message 工厂 `⬜`

```dart
import 'package:flash_im_chat/flash_im_chat.dart';

class TestFixtures {
  static Message message({
    String id = 'msg_1',
    String conversationId = 'conv_1',
    String senderId = 'user_1',
    String senderName = '测试用户',
    String? senderAvatar,
    int seq = 1,
    MessageType type = MessageType.text,
    String content = 'hello',
    MessageStatus status = MessageStatus.sent,
    Map<String, dynamic>? extra,
    DateTime? createdAt,
  }) => Message(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    senderName: senderName,
    senderAvatar: senderAvatar,
    seq: seq,
    type: type,
    content: content,
    status: status,
    extra: extra,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );

  static List<Message> messageList({
    int count = 10,
    String conversationId = 'conv_1',
  }) => List.generate(count, (i) => message(
    id: 'msg_$i',
    conversationId: conversationId,
    seq: i + 1,
    content: '消息 $i',
  ));
}
```

### 8.2 上传结果工厂 `⬜`

```dart
  static ImageUploadResult imageUploadResult({...}) => ImageUploadResult(...);
  static VideoUploadResult videoUploadResult({...}) => VideoUploadResult(...);
  static FileUploadResult fileUploadResult({...}) => FileUploadResult(...);
```

---

## 任务 9：chat_cubit_test.dart — 单元测试 `⬜ 待处理`

文件：`client/modules/flash_im_chat/test/logic/chat_cubit_test.dart`（新建）

### 9.1 测试基础结构 `⬜`

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// ... imports

void main() {
  late MockMessageRepository mockRepo;
  late FakeWsClient fakeWs;
  late MockLocalStore mockStore;

  setUp(() {
    mockRepo = MockMessageRepository();
    fakeWs = FakeWsClient();
    mockStore = MockLocalStore();
    // 注册 fallback values
  });

  tearDown(() {
    fakeWs.dispose();
  });

  ChatCubit buildCubit() => ChatCubit(
    repository: mockRepo,
    wsClient: fakeWs,
    conversationId: 'conv_1',
    currentUserId: 'user_1',
    currentUserName: '测试用户',
    store: mockStore,
  );

  // ... 测试用例
}
```

### 9.2 场景 1：加载消息 `⬜`

```dart
blocTest<ChatCubit, ChatState>(
  '加载消息成功',
  build: () {
    when(() => mockRepo.getMessages('conv_1')).thenAnswer((_) async => TestFixtures.messageList());
    when(() => mockRepo.getReadSeq('conv_1')).thenAnswer((_) async => {});
    when(() => mockRepo.getPinnedMessages('conv_1')).thenAnswer((_) async => []);
    return buildCubit();
  },
  act: (cubit) => cubit.loadMessages(),
  expect: () => [
    isA<ChatLoading>(),
    isA<ChatLoaded>().having((s) => s.messages.length, 'messages', 10),
  ],
);
```

### 9.3 场景 2：发送文本消息 `⬜`

验证：本地消息立即出现（status=sending），WsClient.sendMessage 被调用。

### 9.4 场景 3：收到 ACK `⬜`

验证：本地消息 ID 替换为服务端 ID，status 变为 sent。

### 9.5 场景 4：发送超时 `⬜`

用 fakeAsync 控制时间，验证 10 秒后 status 变为 failed。

### 9.6 场景 5：接收对方消息 `⬜`

通过 fakeWs.chatMessageController.add() 注入消息帧，验证列表更新。

### 9.7 场景 6：图片发送 `⬜`

mock uploadImage 返回结果，验证 WsClient 发送了 IMAGE 类型消息。

### 9.8 场景 7：视频发送 `⬜`

同上，验证 VIDEO 类型。

### 9.9 场景 8：文件发送 `⬜`

同上，验证 FILE 类型。

### 9.10 场景 9：消息撤回 `⬜`

验证调用 recallMessage 后，消息内容变为"你撤回了一条消息"。

### 9.11 场景 10：收到对方撤回 `⬜`

通过 fakeWs.messageRecalledController 注入撤回帧，验证消息内容变更。

### 9.12 场景 11：置顶 `⬜`

验证 pinMessage 调用后 pinnedMessages 列表更新。

### 9.13 场景 12：多选删除 `⬜`

验证 enterMultiSelect → toggleSelect → deleteSelected 后消息从列表移除。

### 9.14 场景 13：加载更多 `⬜`

验证 loadMore 后消息列表增长，hasMore 正确。

### 9.15 场景 14：已读回执 `⬜`

验证 readReceiptStream 触发后 peerReadSeq 更新。

---

## 任务 10：chat_file_mixin.dart — 拆分文件操作 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_file_mixin.dart`（新建）

### 10.1 定义 Mixin `⬜`

```dart
mixin ChatFileMixin on Cubit<ChatState> {
  IMessageRepository get repository;
  WsClient get wsClient;
  String get conversationId;
  String get currentUserId;
  String get currentUserName;
  String? get currentUserAvatar;
  Map<String, String> get pendingMessages;
  int get nextLocalId;  // 返回递增 ID

  Future<void> sendImageFromFile(String filePath) { ... }
  Future<void> sendVideoFromFile(...) { ... }
  Future<void> sendFileFromPicker(String filePath) { ... }
  Future<void> downloadFile(String messageId, String fullUrl, String fileName) { ... }
}
```

### 10.2 从 ChatCubit 搬移方法 `⬜`

搬移：sendImageFromFile、sendVideoFromFile、sendFileFromPicker、downloadFile、_emitDownloadUpdate、_getDownloadDir。

### 10.3 ChatCubit 添加 with + getter 实现 `⬜`

```dart
class ChatCubit extends Cubit<ChatState> with ChatFileMixin, ... {
  @override
  IMessageRepository get repository => _repository;
  @override
  WsClient get wsClient => _wsClient;
  // ...
}
```

### 10.4 跑测试验证 `⬜`

`flutter test` 全部通过。

---

## 任务 11：chat_pin_mixin.dart — 拆分置顶和撤回 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_pin_mixin.dart`（新建）

### 11.1 定义 Mixin `⬜`

```dart
mixin ChatPinMixin on Cubit<ChatState> {
  IMessageRepository get repository;
  String get conversationId;
  String get currentUserId;
  LocalStore? get localStore;

  Future<void> loadPinnedMessages();
  Future<void> pinMessage(String messageId);
  Future<void> unpinMessage(String pinId);
  Future<void> recallMessage(String messageId);
  void handleMessageRecalled(WsFrame frame);
}
```

### 11.2 搬移方法 `⬜`

搬移：loadPinnedMessages、pinMessage、unpinMessage、recallMessage、_handleMessageRecalled、_replaceWithRecalled。

### 11.3 跑测试验证 `⬜`

---

## 任务 12：chat_select_mixin.dart — 拆分多选模式 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_select_mixin.dart`（新建）

### 12.1 定义 Mixin `⬜`

```dart
mixin ChatSelectMixin on Cubit<ChatState> {
  LocalStore? get localStore;
  String get conversationId;
  String get currentUserId;
  VoidCallback? get onConversationChanged;

  void enterMultiSelect(String initialId);
  void exitMultiSelect();
  void toggleSelect(String messageId);
  Future<void> deleteSelected();
}
```

### 12.2 搬移方法 `⬜`

搬移：enterMultiSelect、exitMultiSelect、toggleSelect、deleteSelected。

### 12.3 跑测试验证 `⬜`

---

## 任务 13：最终验证 `⬜ 待处理`

### 13.1 flutter analyze `⬜`

```bash
cd client && flutter analyze
```

期望：No issues found。

### 13.2 flutter test `⬜`

```bash
cd client/modules/flash_im_chat && flutter test
```

期望：14 个测试全部通过。

### 13.3 行数验证 `⬜`

chat_cubit.dart ≤ 400 行。

### 13.4 提交 `⬜`

```bash
git add -A && git commit -m "feat: add IM test infrastructure and refactor ChatCubit into mixins"
```
