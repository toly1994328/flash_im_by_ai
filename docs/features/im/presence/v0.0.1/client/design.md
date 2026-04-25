---
module: im-core + im-chat + im-friend
version: v0.0.1_presence
date: 2026-04-24
tags: [在线状态, 已读回执, WS, Flutter]
---

# 在线状态与已读回执 — 客户端设计报告

> 关联设计：[服务端设计](../server/design.md) | [功能分析](../analysis.md)

## 1. 目标

- WsClient 扩展：新增 userOnlineStream / userOfflineStream / onlineListStream / readReceiptStream 四个事件流
- WsClient 内置在线状态管理：维护 `Set<String> _onlineUserIds`，提供 `isUserOnline(userId)` 查询
- WsClient 新增 `sendReadReceipt(conversationId, readSeq)` 方法
- Dart proto 生成：新增 USER_ONLINE / USER_OFFLINE / ONLINE_LIST / READ_RECEIPT 帧类型和消息
- ChatCubit 扩展：进入聊天页时自动上报已读位置（1 秒防抖），监听 readReceiptStream 更新消息已读状态
- ChatPage 扩展：单聊消息气泡显示已读/未读标记，单聊 AppBar 显示对方在线/离线状态
- FriendCubit/好友列表扩展：好友条目显示在线绿点

## 2. 现状分析

### 已有能力

- `WsClient`：完整的帧分发模式（9 种帧类型，每种一个 StreamController）
- `ChatCubit`：管理消息列表、发送、接收、ACK
- `ChatPage`：消息气泡、输入框、群公告横幅、GROUP_INFO_UPDATE 监听
- `FriendCubit`：管理好友列表、好友申请通知
- `Message` 模型：有 `seq` 字段，可用于已读位置比较

### 缺失

- WsClient 无在线状态管理（无 onlineUserIds 集合）
- WsClient 无 sendReadReceipt 方法
- ChatCubit 不上报已读位置
- ChatPage 不显示已读标记和在线状态
- 好友列表不显示在线绿点

## 3. 核心流程

### 在线状态数据流

```
后端 → USER_ONLINE/OFFLINE/ONLINE_LIST 帧
  → WsClient._onData 分发
  → WsClient 内部更新 _onlineUserIds 集合
  → userOnlineStream / userOfflineStream / onlineListStream 事件流
  → FriendCubit 监听 → 好友列表绿点
  → ChatPage 监听 → AppBar 在线/离线状态
```

WsClient 内部维护 `_onlineUserIds`，收到 ONLINE_LIST 时初始化，收到 USER_ONLINE 时 add，收到 USER_OFFLINE 时 remove。外部通过 `isUserOnline(userId)` 查询，通过 Stream 监听变化。

### 已读回执数据流

```
用户进入聊天页 / 收到新消息
  → ChatCubit 计算当前最大 seq
  → 1 秒防抖
  → WsClient.sendReadReceipt(conversationId, maxSeq)
  → 后端更新 last_read_seq + 通知对方
  → 对方 WsClient 收到 READ_RECEIPT 帧
  → 对方 ChatCubit 更新 peerReadSeq
  → 对方 ChatPage 消息气泡显示"已读"
```

### 已读标记判断逻辑

**单聊**：
- ChatCubit 维护 `peerReadSeq`（对方的已读位置）
- 自己发的消息，如果 `msg.seq <= peerReadSeq`，显示"已读"（蓝色实心勾）
- 否则显示"未读"（空心圆圈）

**群聊**：
- ChatCubit 维护 `membersReadSeq`（`Map<String, int>`，userId → lastReadSeq）
- 收到 READ_RECEIPT 帧时更新对应成员的 readSeq
- 自己发的消息，统计 `membersReadSeq` 中 seq >= msg.seq 的人数
- 0 人已读：空心圆圈
- 部分已读：显示"N人已读"
- 全部已读：蓝色实心勾
- 进入群聊时需要获取所有成员的初始已读位置（通过扩展 GET /groups/{id}/detail 返回 members 的 last_read_seq）

## 4. 项目结构与技术决策

### 变更范围

```
client/modules/
├── flash_im_core/lib/src/
│   ├── logic/ws_client.dart              # 扩展：4 个新 Stream + _onlineUserIds + sendReadReceipt
│   └── data/proto/                       # 重新生成：新增帧类型和消息
├── flash_im_chat/lib/src/
│   ├── logic/chat_cubit.dart             # 扩展：已读上报（防抖）+ readReceiptStream 监听 + peerReadSeq
│   └── view/
│       ├── chat_page.dart                # 扩展：AppBar 在线状态
│       ├── bubble/message_bubble.dart    # 扩展：已读/未读标记（单聊 + 群聊）
│       └── read_receipt_detail.dart      # 新建：群聊已读详情弹窗（已读/未读 Tab）
├── flash_im_friend/lib/src/
│   ├── logic/friend_cubit.dart           # 扩展：监听 userOnlineStream/userOfflineStream
│   └── view/friend_list_page.dart        # 扩展：好友条目在线绿点

client/lib/src/
└── home/view/home_page.dart              # 可能需要传入在线状态相关参数
```

### 技术决策

| 决策 | 方案 | 理由 |
|------|------|------|
| 在线状态集合放 WsClient | WsClient 内部维护 `_onlineUserIds`，不单独建 Cubit | 在线状态是全局的、和 WS 连接生命周期绑定的，放 WsClient 最自然 |
| 已读上报 1 秒防抖 | ChatCubit 内部 Timer，同一会话内合并多次上报 | 避免快速滚动时频繁发送 WS 帧 |
| peerReadSeq 放 ChatCubit | 每个 ChatCubit 实例维护自己会话的 peerReadSeq | 页面级状态，离开页面即销毁 |
| 已读标记单聊和群聊都做 | 单聊用 peerReadSeq，群聊用 membersReadSeq 映射 | 群聊显示"N人已读"，参考项目已实现 |
| 群聊初始已读位置 | 扩展 GET /groups/{id}/detail 返回 members 的 last_read_seq | 进入群聊时一次性获取 |
| 在线绿点放好友列表 | FriendCubit 监听在线状态变化，FriendListPage 渲染绿点 | 在线状态和好友关系强相关 |
| ChatPage 在线状态 | 单聊 ChatPage AppBar 副标题显示"在线"/"离线" | 只在单聊显示，群聊不显示 |
| 初始 peerReadSeq | 进入聊天页时从 HTTP 接口获取（扩展 GET /conversations/{id}/messages 响应） | 需要知道对方当前的已读位置 |

### 第三方依赖

无需新增。

## 5. 验收标准

| 验收条件 | 验收方式 |
|----------|----------|
| 编译通过 | `flutter analyze` 无错误 |
| 好友列表：在线好友显示绿点 | 手动操作（双设备） |
| 好友列表：好友下线后绿点消失 | 手动操作 |
| 单聊 ChatPage：AppBar 显示对方在线/离线 | 手动操作 |
| 单聊 ChatPage：对方上线/下线时状态实时更新 | 手动操作 |
| 已读回执：进入聊天页后自动上报 | 观察后端日志 |
| 已读回执：自己发的消息显示已读/未读标记 | 手动操作（双设备） |
| 已读回执：对方阅读后标记实时变为"已读" | 手动操作 |
| 群聊已读：显示"N人已读" | 手动操作（多设备） |
| 群聊已读：全部已读时显示蓝色实心勾 | 手动操作 |
| 群聊已读：点击"N人已读"弹出已读/未读成员列表 | 手动操作 |

## 6. 暂不实现

| 功能 | 理由 |
|------|------|
| 最后在线时间 | 后端未持久化 |
| 会话列表在线绿点 | 本版只在好友列表和单聊 ChatPage 显示 |
| 已读回执 HTTP 上报接口 | 上报走 WS |
