# ChatCubit 拆分治理方案

日期：2026-05-17　当前行数：772 行

## 一、现状分析

ChatCubit 当前承担了 7 个职责域，30+ 个方法：

| 职责域 | 方法 | 行数（约） |
|--------|------|-----------|
| 消息加载 | loadMessages, loadMore | 60 |
| 文本消息发送 | sendMessage | 70 |
| 图片发送（含上传） | sendImageFromFile | 80 |
| 视频发送（含上传） | sendVideoFromFile | 75 |
| 文件发送（含上传） | sendFileFromPicker | 70 |
| 文件下载 | downloadFile, _emitDownloadUpdate, _getDownloadDir | 45 |
| WS 消息接收 | _handleIncomingMessage | 50 |
| 消息确认 | _handleMessageAck | 45 |
| 发送超时 | _setupTimeout, _markFailed | 20 |
| 消息撤回 | recallMessage, _handleMessageRecalled, _replaceWithRecalled | 60 |
| 引用回复 | setReplyTo, clearReplyTo | 10 |
| 多选模式 | enterMultiSelect, exitMultiSelect, toggleSelect, deleteSelected | 35 |
| 转发 | forwardMessages | 10 |
| 置顶 | loadPinnedMessages, pinMessage, unpinMessage | 20 |
| 复制与删除 | copyMessage, deleteMessage | 20 |
| 已读回执 | _loadReadSeq, _reportReadSeq | 20 |
| 会话预览同步 | _syncConversationPreview | 15 |

## 二、拆分方案

### 原则

1. **Cubit 本体保留核心职责**：消息加载、文本发送、WS 接收、ACK 确认、已读回执
2. **文件操作拆到 Mixin**：上传和下载是独立的 I/O 密集操作，和消息核心逻辑解耦
3. **交互模式拆到 Mixin**：多选、置顶、撤回是 UI 交互模式，不是消息核心流程
4. **不过度拆分**：引用回复（10 行）、复制（5 行）、转发（10 行）太小，留在本体

### 拆分结构

```
flash_im_chat/lib/src/logic/
├── chat_cubit.dart          # 本体（~350 行）
├── chat_file_mixin.dart     # 文件上传 + 下载（~270 行）
├── chat_pin_mixin.dart      # 置顶 + 撤回（~100 行）
└── chat_select_mixin.dart   # 多选模式（~50 行）
```

### 各 Mixin 职责

#### ChatFileMixin（~270 行）

```dart
mixin ChatFileMixin on Cubit<ChatState> {
  // 需要访问的字段（通过抽象 getter 暴露）
  MessageRepository get repository;
  WsClient get wsClient;
  String get conversationId;
  String get currentUserId;
  String get currentUserName;
  String? get currentUserAvatar;

  // 方法
  Future<void> sendImageFromFile(String filePath);
  Future<void> sendVideoFromFile(String filePath, String thumbnailPath, int durationMs, {int width, int height});
  Future<void> sendFileFromPicker(String filePath);
  Future<void> downloadFile(String messageId, String fullUrl, String fileName);
}
```

包含：
- sendImageFromFile（80 行）
- sendVideoFromFile（75 行）
- sendFileFromPicker（70 行）
- downloadFile + _emitDownloadUpdate + _getDownloadDir（45 行）

#### ChatPinMixin（~100 行）

```dart
mixin ChatPinMixin on Cubit<ChatState> {
  MessageRepository get repository;
  String get conversationId;
  String get currentUserId;

  // 置顶
  Future<void> loadPinnedMessages();
  Future<void> pinMessage(String messageId);
  Future<void> unpinMessage(String pinId);

  // 撤回
  Future<void> recallMessage(String messageId);
  void handleMessageRecalled(WsFrame frame);  // 供本体调用
}
```

包含：
- loadPinnedMessages / pinMessage / unpinMessage（20 行）
- recallMessage / _replaceWithRecalled（60 行）

#### ChatSelectMixin（~50 行）

```dart
mixin ChatSelectMixin on Cubit<ChatState> {
  void enterMultiSelect(String initialId);
  void exitMultiSelect();
  void toggleSelect(String messageId);
  Future<void> deleteSelected();
}
```

### ChatCubit 本体（~350 行）

拆分后保留：
- 构造函数 + 字段声明 + close()
- loadMessages / loadMore
- sendMessage（文本）
- _handleIncomingMessage / _handleMessageAck
- _setupTimeout / _markFailed
- setReplyTo / clearReplyTo
- copyMessage / deleteMessage
- forwardMessages
- _loadReadSeq / _reportReadSeq
- _syncConversationPreview

类声明变为：

```dart
class ChatCubit extends Cubit<ChatState>
    with ChatFileMixin, ChatPinMixin, ChatSelectMixin {
  // ...
}
```

## 三、Mixin 访问字段的方式

Mixin 需要访问 ChatCubit 的私有字段。两种方案：

**方案 A：抽象 getter（推荐）**

在 Mixin 中声明抽象 getter，ChatCubit 本体实现：

```dart
mixin ChatFileMixin on Cubit<ChatState> {
  MessageRepository get repository;
  WsClient get wsClient;
  String get conversationId;
  // ...
}

class ChatCubit extends Cubit<ChatState> with ChatFileMixin {
  final MessageRepository _repository;
  @override
  MessageRepository get repository => _repository;
  // ...
}
```

优点：Mixin 不依赖具体实现，可独立测试。

**方案 B：字段改为 protected（去掉下划线）**

把 `_repository` 改为 `repository`，Mixin 直接访问。

优点：代码更简洁。缺点：暴露了内部字段。

**建议用方案 A**，保持封装性。

## 四、执行步骤

1. 创建 `chat_file_mixin.dart`，把文件相关方法搬过去
2. 创建 `chat_pin_mixin.dart`，把置顶和撤回搬过去
3. 创建 `chat_select_mixin.dart`，把多选搬过去
4. ChatCubit 加 `with` 声明，添加抽象 getter 的实现
5. 调整 WS 监听：撤回和置顶的 stream 监听在构造函数中注册，回调转发给 mixin 方法
6. 跑 `flutter analyze` 确认零问题
7. 在模拟器上验证：发图片、发视频、发文件、撤回、置顶、多选删除

## 五、风险评估

| 风险 | 概率 | 影响 | 应对 |
|------|------|------|------|
| Mixin 访问 state 的时序问题 | 低 | Mixin 中 emit 后立即读 state 可能拿到旧值 | 和本体一样用 `final s = state` 模式 |
| WS 监听注册顺序 | 低 | 构造函数中注册，Mixin 方法此时已可用 | Dart mixin 初始化顺序保证 |
| 循环依赖 | 无 | Mixin 只依赖 Cubit\<ChatState\>，不依赖 ChatCubit | 架构上不会循环 |

## 六、预期收益

| 指标 | 拆分前 | 拆分后 |
|------|--------|--------|
| chat_cubit.dart 行数 | 772 | ~350 |
| 文件数 | 1 | 4 |
| 单文件最大行数 | 772 | ~350 |
| 可独立测试的单元 | 1 | 4 |

拆分后每个文件职责单一，新增功能时能快速定位该改哪个文件。比如后续加"语音消息"，只需在 ChatFileMixin 里加一个 `sendVoiceFromFile` 方法。
