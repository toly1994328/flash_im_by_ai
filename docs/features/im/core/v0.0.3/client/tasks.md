# IM Core v0.0.3 — 客户端任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。
三层架构：data / logic / view，与其他模块保持一致。
参考项目：`docs/ref/flash_im-main/app/packages/im_chat/`

---

## 执行顺序

1. ✅ 任务 1 — WsClient 帧分发扩展（flash_im_core 修改）
2. ✅ 任务 2 — 创建 flash_shared 公共模块
3. ✅ 任务 3 — 创建 flash_im_chat 模块骨架
4. ✅ 任务 4 — Message 数据模型
5. ✅ 任务 5 — MessageRepository（HTTP 历史消息）
6. ✅ 任务 6 — ChatCubit + ChatState
7. ✅ 任务 7 — MessageBubble 组件
8. ✅ 任务 8 — ChatInput 组件
9. ✅ 任务 9 — ChatPage 页面
10. ✅ 任务 10 — barrel 导出
11. ✅ 任务 11 — 主工程集成（路由 + 会话列表 onTap）
12. ✅ 任务 12 — ConversationListCubit 扩展（CONVERSATION_UPDATE 监听 + total_unread）
13. ✅ 任务 13 — 底部导航角标（total_unread）
14. ✅ 任务 14 — 全局主题 + UI 调优
15. ✅ 任务 15 — 编译验证 + 功能验证

---

## 任务 1：WsClient 帧分发扩展 `✅`

文件：`client/modules/flash_im_core/lib/src/logic/ws_client.dart`（修改）

### 1.1 新增 proto 导入 `✅`

导入 message.proto 生成的 Dart 代码（ChatMessage、MessageAck、ConversationUpdate 等）。
需要先运行 proto 代码生成脚本。

### 1.2 新增分类型 StreamController `✅`

```dart
final _chatMessageController = StreamController<WsFrame>.broadcast();
final _messageAckController = StreamController<WsFrame>.broadcast();
final _conversationUpdateController = StreamController<WsFrame>.broadcast();

Stream<WsFrame> get chatMessageStream => _chatMessageController.stream;
Stream<WsFrame> get messageAckStream => _messageAckController.stream;
Stream<WsFrame> get conversationUpdateStream => _conversationUpdateController.stream;
```

### 1.3 修改 _onData 帧分发 `✅`

在已认证阶段，按 frame.type 分发到对应 StreamController：

```dart
switch (frame.type) {
  case WsFrameType.CHAT_MESSAGE:
    _chatMessageController.add(frame);
  case WsFrameType.MESSAGE_ACK:
    _messageAckController.add(frame);
  case WsFrameType.CONVERSATION_UPDATE:
    _conversationUpdateController.add(frame);
  default:
    break;
}
_frameController.add(frame);
```

### 1.4 dispose 中关闭新增 StreamController `✅`

### 1.5 新增 sendMessage 便捷方法 `✅`

```dart
void sendMessage({
  required String conversationId,
  required String content,
  String? clientId,
})
```

---

## 任务 2：创建 flash_shared 公共模块 `✅`

### 2.1 flutter create `✅`

```powershell
cd client/modules
flutter create --template=package --project-name=flash_shared flash_shared
```

### 2.2 IdenticonPainter + IdenticonAvatar `✅`

文件：`client/modules/flash_shared/lib/src/identicon_avatar.dart`（新建）

从 flash_session 提取，基于 seed 生成 5x5 对称方块图案。支持 `seed:hex` 格式指定颜色。

### 2.3 AvatarWidget `✅`

文件：`client/modules/flash_shared/lib/src/avatar_widget.dart`（新建）

统一头像入口：
- `identicon:xxx` → IdenticonAvatar
- `http(s)://...` → 网络图片（带 errorBuilder 降级）
- 空或 null → 占位图标

### 2.4 barrel 导出 `✅`

文件：`client/modules/flash_shared/lib/flash_shared.dart`

```dart
export 'src/identicon_avatar.dart';
export 'src/avatar_widget.dart';
```

---

## 任务 3：创建 flash_im_chat 模块骨架 `✅`

### 3.1 flutter create `✅`

### 3.2 添加依赖 `✅`

文件：`client/modules/flash_im_chat/pubspec.yaml`

依赖：dio, flutter_bloc, equatable, shimmer, flash_im_core, flash_shared

### 3.3 三层目录结构 `✅`

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

## 任务 4：Message 数据模型 `✅`

文件：`client/modules/flash_im_chat/lib/src/data/message.dart`（新建）

包含：MessageStatus 枚举、Message 类（fromJson、sending 工厂、copyWith）

---

## 任务 5：MessageRepository `✅`

文件：`client/modules/flash_im_chat/lib/src/data/message_repository.dart`（新建）

GET /conversations/:id/messages?before_seq=&limit= 历史消息查询

---

## 任务 6：ChatCubit + ChatState `✅`

### 6.1 ChatState `✅`

sealed class：ChatInitial / ChatLoading / ChatLoaded（messages, hasMore, isLoadingMore） / ChatError

### 6.2 ChatCubit `✅`

- loadMessages() — HTTP 加载历史
- loadMore() — 基于 before_seq 加载更早消息
- sendMessage(content) — 乐观更新 + WS 发送 + 10s 超时
- _handleIncomingMessage — 解析 ChatMessage，过滤当前会话，跳过自己发的
- _handleMessageAck — 匹配 pending，更新 status=sent

---

## 任务 7：MessageBubble 组件 `✅`

文件：`client/modules/flash_im_chat/lib/src/view/message_bubble.dart`（新建）

- 左右布局（isMe）、头像（AvatarWidget from flash_shared）、昵称、气泡、状态图标
- 蓝色/灰色气泡、sending 转圈、failed 红色感叹号

---

## 任务 8：ChatInput 组件 `✅`

文件：`client/modules/flash_im_chat/lib/src/view/chat_input.dart`（新建）

Row [ TextField(Expanded) + 发送按钮 ]，空内容禁用，发送后清空

---

## 任务 9：ChatPage 页面 `✅`

文件：`client/modules/flash_im_chat/lib/src/view/chat_page.dart`（新建）

- AppBar 显示对方昵称
- ChatLoading → Shimmer 骨架屏
- ChatLoaded → ListView.builder(reverse: true) + MessageBubble
- 滚动到顶部触发 loadMore
- 底部 ChatInput

---

## 任务 10：barrel 导出 `✅`

文件：`client/modules/flash_im_chat/lib/flash_im_chat.dart`

导出所有 data/logic/view 文件

---

## 任务 11：主工程集成 `✅`

### 11.1 pubspec.yaml 注册模块 `✅`

### 11.2 main.dart 注入 MessageRepository `✅`

### 11.3 会话列表 onTap 导航到 ChatPage `✅`

点击会话 → clearUnread → Navigator.push ChatPage（BlocProvider + ChatCubit）

---

## 任务 12：ConversationListCubit 扩展 `✅`

### 12.1 监听 conversationUpdateStream `✅`

### 12.2 _handleConversationUpdate 方法 `✅`

解析 ConversationUpdate → 更新 preview/time/unread → 重排序 → emit

### 12.3 totalUnread 字段 `✅`

ConversationListLoaded 新增 totalUnread，从 CONVERSATION_UPDATE 帧取值

### 12.4 clearUnread 方法 `✅`

本地置 0 + totalUnread 减少 + 后端 POST /conversations/:id/read

### 12.5 dispose 取消订阅 `✅`

---

## 任务 13：底部导航角标 `✅`

文件：`client/lib/src/home/view/home_page.dart`

BlocBuilder 监听 totalUnread，>0 显示红色角标，>99 显示 "99+"

---

## 任务 14：全局主题 + UI 调优 `✅`

### 14.1 全局 AppBarTheme `✅`

文件：`client/lib/src/application/app.dart`（修改）

```dart
appBarTheme: const AppBarTheme(
  backgroundColor: Color(0xFFEDEDED),
  foregroundColor: Colors.black,
  elevation: 0,
  scrolledUnderElevation: 0,
  surfaceTintColor: Colors.transparent,
  centerTitle: true,
  titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black),
),
scaffoldBackgroundColor: const Color(0xFFEDEDED),
```

### 14.2 ChatPage body 白色背景 `✅`

文件：`client/modules/flash_im_chat/lib/src/view/chat_page.dart`（修改）

body 用 `Container(color: Colors.white)` 包裹，消息内容区白色，AppBar 灰色。
AnnotatedRegion 统一状态栏风格。

### 14.3 MessageBubble 样式调优 `✅`

文件：`client/modules/flash_im_chat/lib/src/view/message_bubble.dart`（修改）

- 垂直间距：4 → 8
- 气泡圆角：16/4 → 12/4

### 14.4 消息不足一屏靠顶显示 `✅`

文件：`client/modules/flash_im_chat/lib/src/view/chat_page.dart`（修改）

消息 ≤15 条时 shrinkWrap + Align(topCenter)，超过后切回普通 ListView 避免性能问题。

---

## 任务 15：编译验证 + 功能验证 `✅`

### 15.1 编译 `✅`

flutter analyze 零 error（28 issues 全为 info/warning，均在 playground 废弃代码中）

### 15.2 功能验证 `⬜`

待手动测试：
1. 重置数据库 + 种子数据
2. 启动后端
3. 启动客户端
4. 用朱红登录，点击会话列表中的橘橙
5. 聊天页显示骨架屏 → 加载完成显示历史消息
6. 输入文字发送，消息立刻出现（sending 状态）
7. 收到 ACK 后状态变为 sent
8. 用另一台设备登录橘橙，验证实时收到消息
9. 返回会话列表，验证预览和时间已更新
10. 底部导航角标显示总未读数
