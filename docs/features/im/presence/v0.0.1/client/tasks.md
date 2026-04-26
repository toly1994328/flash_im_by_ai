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

1. ✅ 任务 1 — Dart proto 生成（新增帧类型 + 消息）
2. ✅ 任务 2 — WsClient 扩展（4 个新 Stream + 在线状态管理 + sendReadReceipt）
3. ✅ 任务 3 — ChatCubit 扩展（已读上报防抖 + readReceiptStream 监听 + peerReadSeq / membersReadSeq）
4. ✅ 任务 4 — MessageBubble 已读标记（单聊 + 群聊）
5. ✅ 任务 5 — ReadReceiptDetailSheet 群聊已读详情弹窗
6. ✅ 任务 6 — ChatPage 扩展（AppBar 在线状态 + 已读参数传入）
7. ✅ 任务 7 — FriendCubit + 好友列表在线绿点
8. ✅ 任务 8 — home_page 组装
9. ✅ 任务 9 — 编译验证（flutter analyze 通过，无 error）
10. ✅ 任务 10 — 活跃会话不累加未读（ConversationListCubit activeConversationId + markRead）
11. ✅ 任务 11 — 会话列表单聊在线绿点（ConversationTile isOnline + ConversationListPage onlineUserIds）

---

## 任务 1：Dart proto 生成 `✅ 已完成`

### 1.1 生成 Dart proto 文件 `✅`

新增帧类型 USER_ONLINE / USER_OFFLINE / ONLINE_LIST / READ_RECEIPT。
新增消息 UserStatusNotification / OnlineListNotification / ReadReceiptRequest / ReadReceiptNotification。

### 1.2 手动补 clone 方法 `✅`

新增的 proto 类补 `clone() => deepCopy()`（protoc_plugin 25.0.0 兼容性问题）。

---

## 任务 2：WsClient 扩展 `✅ 已完成`

文件：`client/modules/flash_im_core/lib/src/logic/ws_client.dart`

### 2.1 新增 4 个 StreamController `✅`

userOnlineStream / userOfflineStream / onlineListStream / readReceiptStream

### 2.2 在线状态集合 `✅`

`Set<String> _onlineUserIds` + `isUserOnline(userId)` + `onlineUserIds` getter

### 2.3 帧分发 switch 新增 `✅`

USER_ONLINE → _handleUserOnline + add to stream
USER_OFFLINE → _handleUserOffline + add to stream
ONLINE_LIST → _handleOnlineList + add to stream
READ_RECEIPT → add to stream

### 2.4 内部处理方法 `✅`

_handleUserOnline: add to _onlineUserIds
_handleUserOffline: remove from _onlineUserIds
_handleOnlineList: clear + addAll

### 2.5 sendReadReceipt 方法 `✅`

构建 ReadReceiptRequest proto 帧发送。

### 2.6 dispose + 断连清理 `✅`

dispose 关闭 4 个新 Controller，_onDisconnected 清空 _onlineUserIds。

---

## 任务 3：ChatCubit 扩展 `✅ 已完成`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_cubit.dart`

### 3.1 新增状态字段 `✅`

_peerReadSeq / _membersReadSeq / _readReceiptTimer / _readReceiptSub / _readSeqVersion

### 3.2 构造函数新增 isGroup 参数 `✅`

### 3.3 监听 readReceiptStream `✅`

收到通知后更新 _peerReadSeq（单聊）或 _membersReadSeq（群聊），emit copyWith + readSeqVersion++

### 3.4 已读上报（1 秒防抖） `✅`

_reportReadSeq 在 loadMessages 完成后和 _handleIncomingMessage 收到新消息后调用。

### 3.5 _loadReadSeq HTTP 获取初始已读位置 `✅`

调 GET /conversations/{id}/read-seq，单聊取 values.first，群聊取整个 map。

### 3.6 close 中清理 `✅`

_readReceiptSub?.cancel() + _readReceiptTimer?.cancel()

### 3.7 Equatable 修复 `✅`

ChatLoaded 新增 readSeqVersion 字段，加入 props，解决 BlocBuilder 不重建的问题。

---

## 任务 4：MessageBubble 已读标记 `✅ 已完成`

文件：`client/modules/flash_im_chat/lib/src/view/bubble/message_bubble.dart`

### 4.1 新增参数 `✅`

peerReadSeq / membersReadSeq / currentUserId / isGroup / onReadCountTap

### 4.2 已读指示器渲染 `✅`

只在 isMe && msg.status == sent && msg.seq > 0 时显示。

### 4.3 三种图标组件 `✅`

- _AllReadIcon：蓝色实心勾（14px）
- _UnreadCircle：空心蓝色圆圈（12px）
- _ReadCountCircle：蓝色圆圈 + 数字（可点击）

---

## 任务 5：ReadReceiptDetailSheet `✅ 已完成`

文件：`client/modules/flash_im_chat/lib/src/view/read_receipt_detail.dart`（新建）

### 5.1 页面结构 `✅`

BottomSheet + TabBar（已读 N / 未读 N）+ 成员列表（头像 + 昵称）

### 5.2 数据加载 `✅`

调 GET /conversations/{id}/messages/{mid}/read-status，通过 fetcher 回调注入。

---

## 任务 6：ChatPage 扩展 `✅ 已完成`

文件：`client/modules/flash_im_chat/lib/src/view/chat_page.dart`

### 6.1 AppBar 在线状态（单聊） `✅`

标题下方显示"在线"（绿色）/"离线"（灰色）文字，无圆点。监听 userOnlineStream / userOfflineStream 实时更新。

### 6.2 MessageBubble 传入已读参数 `✅`

从 ChatCubit 获取 peerReadSeq / membersReadSeq 传入。

### 6.3 群聊已读详情回调 `✅`

onReadCountTap 弹出 ReadReceiptDetailSheet。

---

## 任务 7：FriendCubit + 好友列表在线绿点 `✅ 已完成`

### 7.1 FriendCubit 监听在线状态 `✅`

FriendState 新增 onlineIds 集合。监听 userOnlineStream / userOfflineStream / onlineListStream。

### 7.2 好友列表绿点 `✅`

IndexedContactList 头像右下角绿色圆点（微信绿 0xFF07C160，12px，白色边框 2px）。

---

## 任务 8：home_page 组装 `✅ 已完成`

ChatCubit 构建时传入 isGroup 参数。进入聊天页时调 setActiveConversation，返回时 clearActiveConversation。ConversationListPage 外层包 BlocBuilder<FriendCubit> 传入 onlineUserIds。

---

## 任务 9：编译验证 `✅ 已完成`

### 9.1 flutter analyze `✅`

无 error，只有 info/warning（大部分在 playground 废弃代码中）。


---

## 任务 10：活跃会话不累加未读 `✅ 已完成`

文件：`client/modules/flash_im_conversation/lib/src/logic/conversation_list_cubit.dart`

### 10.1 activeConversationId 字段 `✅`

新增 `_activeConversationId`，`setActiveConversation(id)` / `clearActiveConversation()` 方法。

### 10.2 _handleUpdate 跳过活跃会话未读 `✅`

收到 ConversationUpdate 时，如果 conversationId == _activeConversationId，unreadCount 不累加，同时调 `markRead` 通知后端清零（避免重启后幽灵未读）。

### 10.3 home_page 集成 `✅`

进入聊天页时 `_convCubit.setActiveConversation(id)`，返回时 `.then((_) => _convCubit.clearActiveConversation())`。

---

## 任务 11：会话列表单聊在线绿点 `✅ 已完成`

### 11.1 ConversationTile 新增 isOnline 参数 `✅`

文件：`client/modules/flash_im_conversation/lib/src/view/conversation_tile.dart`

单聊头像右下角绿点：微信绿 0xFF07C160，12px，白色边框 2px，Positioned(bottom: -2, right: -2)。

### 11.2 ConversationListPage 新增 onlineUserIds 参数 `✅`

文件：`client/modules/flash_im_conversation/lib/src/view/conversation_list_page.dart`

根据 conversation.peerUserId 判断是否在线，传入 ConversationTile。

### 11.3 home_page 传入 onlineUserIds `✅`

ConversationListPage 外层包 `BlocBuilder<FriendCubit, FriendState>`，将 `friendState.onlineIds` 传入。
