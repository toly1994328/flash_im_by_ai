# 在线状态与已读回执 — 客户端任务清单

基于 [design.md](design.md) 设计，列出需要创建/修改的具体细节。

全局约束：
- 在线状态集合放 WsClient 内部（`_onlineUserIds`），不单独建 Cubit
- 已读上报 1 秒防抖，ChatCubit 内部 Timer
- 单聊已读用 peerReadSeq，群聊已读用 membersReadSeq
- 已读标记只在自己发的消息上显示
- 后端只广播给好友，前端不需要额外过滤

---

## 执行顺序

1. ⬜ 任务 1 — Dart proto 生成（新增帧类型 + 消息）
2. ⬜ 任务 2 — WsClient 扩展（4 个新 Stream + 在线状态管理 + sendReadReceipt）
3. ⬜ 任务 3 — ChatCubit 扩展（已读上报防抖 + readReceiptStream 监听 + peerReadSeq / membersReadSeq）
4. ⬜ 任务 4 — MessageBubble 已读标记（单聊 + 群聊）
5. ⬜ 任务 5 — ReadReceiptDetailSheet 群聊已读详情弹窗
6. ⬜ 任务 6 — ChatPage 扩展（AppBar 在线状态 + 已读参数传入）
7. ⬜ 任务 7 — FriendCubit + 好友列表在线绿点
8. ⬜ 任务 8 — home_page 组装
9. ⬜ 任务 9 — 编译验证

---

## 任务 1：Dart proto 生成 `⬜ 待处理`

### 1.1 生成 Dart proto 文件 `⬜`

```bash
protoc --plugin=protoc-gen-dart="..." --dart_out=client/modules/flash_im_core/lib/src/data/proto proto/message.proto proto/ws.proto
```

### 1.2 手动补 clone 方法 `⬜`

新增的 proto 类（UserStatusNotification、OnlineListNotification、ReadReceiptRequest、ReadReceiptNotification）需要手动补 `clone() => deepCopy()` 和 `copyWith()`（protoc_plugin 25.0.0 兼容性问题）。

---

## 任务 2：WsClient 扩展 `⬜ 待处理`

文件：`client/modules/flash_im_core/lib/src/logic/ws_client.dart`（修改）

### 2.1 新增 4 个 StreamController `⬜`

```dart
final _userOnlineController = StreamController<WsFrame>.broadcast();
final _userOfflineController = StreamController<WsFrame>.broadcast();
final _onlineListController = StreamController<WsFrame>.broadcast();
final _readReceiptController = StreamController<WsFrame>.broadcast();

Stream<WsFrame> get userOnlineStream => _userOnlineController.stream;
Stream<WsFrame> get userOfflineStream => _userOfflineController.stream;
Stream<WsFrame> get onlineListStream => _onlineListController.stream;
Stream<WsFrame> get readReceiptStream => _readReceiptController.stream;
```

### 2.2 在线状态集合 `⬜`

```dart
final Set<String> _onlineUserIds = {};

bool isUserOnline(String userId) => _onlineUserIds.contains(userId);
Set<String> get onlineUserIds => Set.unmodifiable(_onlineUserIds);
```

### 2.3 帧分发 switch 新增 `⬜`

```dart
case WsFrameType.USER_ONLINE:
    _handleUserOnline(frame);
    _userOnlineController.add(frame);
case WsFrameType.USER_OFFLINE:
    _handleUserOffline(frame);
    _userOfflineController.add(frame);
case WsFrameType.ONLINE_LIST:
    _handleOnlineList(frame);
    _onlineListController.add(frame);
case WsFrameType.READ_RECEIPT:
    _readReceiptController.add(frame);
```

### 2.4 内部处理方法 `⬜`

```dart
void _handleUserOnline(WsFrame frame) {
    final notif = UserStatusNotification.fromBuffer(frame.payload);
    _onlineUserIds.add(notif.userId);
}

void _handleUserOffline(WsFrame frame) {
    final notif = UserStatusNotification.fromBuffer(frame.payload);
    _onlineUserIds.remove(notif.userId);
}

void _handleOnlineList(WsFrame frame) {
    final notif = OnlineListNotification.fromBuffer(frame.payload);
    _onlineUserIds.clear();
    _onlineUserIds.addAll(notif.userIds);
}
```

### 2.5 sendReadReceipt 方法 `⬜`

```dart
void sendReadReceipt({required String conversationId, required int readSeq}) {
    final req = ReadReceiptRequest()
      ..conversationId = conversationId
      ..readSeq = Int64(readSeq);
    final frame = WsFrame()
      ..type = WsFrameType.READ_RECEIPT
      ..payload = req.writeToBuffer();
    sendFrame(frame);
}
```

### 2.6 dispose 中关闭 + 断连时清空在线集合 `⬜`

dispose 中关闭 4 个新 Controller。
`_onDisconnected` 中清空 `_onlineUserIds`。

---

## 任务 3：ChatCubit 扩展 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_cubit.dart`（修改）

### 3.1 新增状态字段 `⬜`

```dart
int _peerReadSeq = 0;                    // 单聊：对方已读位置
Map<String, int> _membersReadSeq = {};   // 群聊：成员已读映射
Timer? _readReceiptTimer;                // 防抖定时器
StreamSubscription? _readReceiptSub;     // 已读回执监听
```

### 3.2 构造函数新增参数 `⬜`

```dart
final bool isGroup;
final int initialPeerReadSeq;                    // 单聊初始已读位置
final Map<String, int> initialMembersReadSeq;    // 群聊初始已读映射
```

### 3.3 监听 readReceiptStream `⬜`

```dart
_readReceiptSub = _wsClient.readReceiptStream.listen((frame) {
    final notif = ReadReceiptNotification.fromBuffer(frame.payload);
    if (notif.conversationId != conversationId) return;
    if (isGroup) {
        _membersReadSeq[notif.userId] = notif.readSeq.toInt();
    } else {
        _peerReadSeq = notif.readSeq.toInt();
    }
    // 触发 UI 刷新
    final s = state;
    if (s is ChatLoaded) emit(s.copyWith());
});
```

### 3.4 已读上报（1 秒防抖） `⬜`

```dart
void _reportReadSeq(int maxSeq) {
    _readReceiptTimer?.cancel();
    _readReceiptTimer = Timer(const Duration(seconds: 1), () {
        _wsClient.sendReadReceipt(conversationId: conversationId, readSeq: maxSeq);
    });
}
```

在 `loadMessages` 完成后和 `_handleIncomingMessage` 收到新消息后调用 `_reportReadSeq`。

### 3.5 暴露已读状态给 UI `⬜`

```dart
int get peerReadSeq => _peerReadSeq;
Map<String, int> get membersReadSeq => Map.unmodifiable(_membersReadSeq);
```

### 3.6 close 中清理 `⬜`

```dart
_readReceiptSub?.cancel();
_readReceiptTimer?.cancel();
```

---

## 任务 4：MessageBubble 已读标记 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/bubble/message_bubble.dart`（修改）

### 4.1 新增参数 `⬜`

```dart
final int? peerReadSeq;                  // 单聊对方已读位置
final Map<String, int> membersReadSeq;   // 群聊成员已读映射
final String? currentUserId;             // 排除自己
final bool isGroup;
final VoidCallback? onReadCountTap;      // 点击"N人已读"回调
```

### 4.2 已读指示器渲染 `⬜`

只在 `isMe && msg.status == sent && msg.seq > 0` 时显示，放在气泡左侧底部对齐。

```dart
Widget _buildReadReceiptIndicator():
    if isGroup: return _buildGroupReadIndicator()
    else: return _buildPrivateReadIndicator()

Widget _buildPrivateReadIndicator():
    isRead = (peerReadSeq ?? 0) >= msg.seq
    return isRead ? _AllReadIcon() : _UnreadCircle()

Widget _buildGroupReadIndicator():
    readCount = membersReadSeq.entries
        .where(e => e.key != currentUserId && e.value >= msg.seq)
        .length
    totalMembers = membersReadSeq.entries
        .where(e => e.key != currentUserId)
        .length
    if readCount >= totalMembers: return _AllReadIcon()
    if readCount == 0: return _UnreadCircle()
    return _ReadCountCircle(count: readCount)  // 可点击
```

### 4.3 图标组件 `⬜`

```dart
// 全部已读：蓝色实心勾（14px）
class _AllReadIcon → Icon(Icons.check_circle, size: 14, color: Color(0xFFB8D9F5))

// 未读：空心蓝色圆圈（12px）
class _UnreadCircle → Container(shape: circle, border: Color(0xFF177EE6))

// 部分已读：蓝色圆圈 + 数字（可点击）
class _ReadCountCircle → Container(border: Color(0xFF177EE6), child: Text(count))
```

---

## 任务 5：ReadReceiptDetailSheet 群聊已读详情弹窗 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/read_receipt_detail.dart`（新建）

### 5.1 页面结构 `⬜`

```dart
class ReadReceiptDetailSheet extends StatefulWidget {
    final String messageId;
    final String conversationId;
    final String? baseUrl;
    final MessageRepository repository;
}
```

### 5.2 数据加载 `⬜`

initState 中调 `GET /conversations/{conv_id}/messages/{msg_id}/read-status`，获取 read_members 和 unread_members。

### 5.3 UI 布局 `⬜`

- 拖拽指示器
- TabBar：已读 N / 未读 N
- TabBarView：两个成员列表（头像 + 昵称）

---

## 任务 6：ChatPage 扩展 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/chat_page.dart`（修改）

### 6.1 AppBar 在线状态（单聊） `⬜`

单聊 ChatPage 的 AppBar title 下方显示副标题：
- 在线：绿色小圆点 + "在线"
- 离线：灰色小圆点 + "离线"

监听 `WsClient.userOnlineStream` / `userOfflineStream`，实时更新。
初始值从 `WsClient.isUserOnline(peerUserId)` 获取。

### 6.2 MessageBubble 传入已读参数 `⬜`

从 ChatCubit 获取 `peerReadSeq` / `membersReadSeq`，传入每个 MessageBubble。

### 6.3 群聊已读详情回调 `⬜`

MessageBubble 的 `onReadCountTap` 回调中弹出 ReadReceiptDetailSheet。

---

## 任务 7：FriendCubit + 好友列表在线绿点 `⬜ 待处理`

### 7.1 FriendCubit 监听在线状态 `⬜`

文件：`client/modules/flash_im_friend/lib/src/logic/friend_cubit.dart`（修改）

新增监听 `WsClient.userOnlineStream` 和 `userOfflineStream`。
FriendState 新增 `Set<String> onlineIds`。
收到上线/下线通知时更新 onlineIds，emit 新状态。
初始化时从 `WsClient.onlineUserIds` 获取初始值。

### 7.2 好友列表绿点 `⬜`

文件：`client/modules/flash_im_friend/lib/src/view/friend_list_page.dart`（修改）

好友条目头像右下角显示绿色小圆点（8px），根据 `state.onlineIds.contains(friend.friendId)` 判断。

---

## 任务 8：home_page 组装 `⬜ 待处理`

文件：`client/lib/src/home/view/home_page.dart`（修改）

### 8.1 ChatCubit 构建传入新参数 `⬜`

所有 ChatCubit 构建时传入 `isGroup`。
单聊传入 `initialPeerReadSeq`（需要从某处获取，可能需要扩展会话详情接口）。
群聊传入 `initialMembersReadSeq`（从 groupDetailFetcher 获取）。

### 8.2 ChatPage 传入 peerUserId `⬜`

单聊 ChatPage 需要 `peerUserId` 来查询在线状态（已有参数）。

---

## 任务 9：编译验证 `⬜ 待处理`

### 9.1 flutter analyze `⬜`

```bash
flutter analyze
```

### 9.2 手动测试路径 `⬜`

1. 好友列表 → 在线好友显示绿点
2. 好友下线 → 绿点消失
3. 单聊 ChatPage → AppBar 显示"在线"/"离线"
4. 对方上线/下线 → 状态实时更新
5. 进入聊天页 → 后端日志显示 READ_RECEIPT
6. 自己发的消息 → 显示空心圆圈（未读）
7. 对方打开聊天页 → 标记变为蓝色实心勾（已读）
8. 群聊 → 显示"N人已读"
9. 群聊 → 点击"N人已读" → 弹出已读/未读成员列表
