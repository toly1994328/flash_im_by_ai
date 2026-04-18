---
module: im-group
version: v0.0.1
date: 2026-04-12
tags: [群聊, 创建, Flutter]
---

# 群聊（创建与加入） — 客户端设计报告

> 关联设计：[服务端设计](../server/design.md) | [功能分析](../analysis.md)

## 1. 目标

- 创建群聊页：微信风格选人页（FlashSearchBar + 已选头像横条 + 字母索引分组 + 绿色圆形勾选），不需要输入群名，自动用成员昵称拼接 + `initialSelectedIds` 预选支持（从单聊详情页发起）
- 单聊详情页：显示对方信息 + "+"按钮跳转创建群聊页（预选对方）
- 我的群聊页：通讯录"群聊"入口 → 已加入群聊列表 + FlashSearchBar 本地过滤搜索
- 群聊消息气泡适配：群聊中他人消息显示 sender_name（当前已显示，需确认群聊场景正确）
- 群聊会话列表适配：群聊显示群名称 + 默认群图标（grid: 宫格头像）
- ChatPage 右上角按钮：单聊显示"..."进入详情页，群聊显示群图标

## 2. 现状分析

### 已有能力

- `flash_im_conversation`：ConversationRepository（createPrivate/getList/delete/markRead/getById）、ConversationListCubit（分页+实时更新）、ConversationListPage、ConversationTile
- `flash_im_chat`：ChatCubit（消息收发+乐观更新+ACK）、ChatPage、MessageBubble（已显示 senderName/senderAvatar）
- `flash_im_core`：WsClient（连接/认证/心跳/帧分发），已有 chatMessageStream/messageAckStream/conversationUpdateStream/friendRequestStream/friendAcceptedStream/friendRemovedStream
- `flash_im_friend`：FriendCubit（好友列表+申请管理）、FriendListPage、FriendDetailPage
- `flash_shared`：AvatarWidget 共享组件
- Protobuf：proto 已生成（任务 2 已完成）
- Conversation 模型已有 `type` 字段（0=单聊, 1=群聊）、`displayName`/`displayAvatar` getter

### 缺失

- 无创建群聊页面
- 无单聊详情页
- ConversationRepository 无 `createGroup` 方法
- ConversationTile 的头像只用 `peerAvatar`，群聊时应用 `displayAvatar`（conversations.avatar）
- ChatPage 右上角无按钮

## 3. 数据模型与接口

### 客户端新增模型

```dart
/// CreateGroupPage 返回值
class CreateGroupResult {
  final String name;
  final List<int> memberIds;
}

/// 可选成员（CreateGroupPage 用，避免依赖 flash_im_friend）
class SelectableMember {
  final String id;
  final String nickname;
  final String? avatar;
  final String letter; // 拼音首字母，由调用方传入
}
```

### ConversationRepository 新增方法

```dart
/// 获取会话列表（支持 type 过滤）
Future<List<Conversation>> getList({int limit = 20, int offset = 0, int? type});

/// 创建群聊
Future<Conversation> createGroup({required String name, required List<int> memberIds});
```

### 接口对应

| 客户端方法 | 后端接口 |
|-----------|---------|
| getList(type: 1) | GET /conversations?type=1 |
| createGroup | POST /conversations (type=group) |

## 4. 核心流程

### 创建群聊（从消息 Tab "+"按钮）

```mermaid
sequenceDiagram
    participant U as 用户
    participant Page as CreateGroupPage
    participant Repo as ConversationRepository
    participant API as 后端

    U->>Page: 点击"+"，进入创建群聊页
    U->>Page: 输入群名 + 勾选好友
    U->>Page: 点击"创建(N)"
    Page->>Repo: createGroup(name, memberIds)
    Repo->>API: POST /conversations {type:"group",...}
    API-->>Repo: Conversation
    Repo-->>Page: Conversation
    Page->>U: Navigator.push(ChatPage)
```

### 从单聊发起群聊

```mermaid
sequenceDiagram
    participant U as 用户
    participant Chat as ChatPage
    participant Info as 单聊详情页
    participant CG as 创建群聊页
    participant API as 后端

    U->>Chat: 点击右上角
    Chat->>Info: 进入详情页
    U->>Info: 点击添加成员
    Info->>CG: 进入创建群聊页 预选对方
    U->>CG: 选好友 输入群名 点击创建
    CG-->>Info: 返回 CreateGroupResult
    Info->>API: POST /conversations
    API-->>Info: 返回 Conversation
    Info->>U: 进入群聊 ChatPage
```

## 5. 项目结构与技术决策

### 变更范围

```
client/modules/
├── flash_shared/lib/src/
│   ├── group_avatar_widget.dart          # 新建：九宫格头像组件（解析 grid: 格式）
│   └── popup_menu_button.dart            # 新建：微信风格弹出菜单（WxPopupMenuButton）
├── flash_im_group/lib/src/               # 新建：群聊独立模块
│   ├── data/
│   │   ├── group_repository.dart         # 新建：createGroup
│   │   └── group_models.dart             # 新建：CreateGroupResult / SelectableMember
│   └── view/
│       ├── create_group_page.dart        # 新建：微信风格选人页
│       └── my_groups_page.dart           # 新建：我的群聊列表
├── flash_im_conversation/lib/src/
│   ├── data/
│   │   ├── conversation_repository.dart  # 修改：getList type 过滤
│   │   └── conversation.dart             # 修改：新增 isGroup getter
│   ├── logic/
│   │   └── conversation_list_cubit.dart  # 修复：_handleUpdate 群聊更新时保留 avatar
│   └── view/
│       └── conversation_tile.dart        # 修改：群聊 grid: 宫格头像 + 默认群图标
├── flash_im_chat/lib/src/
│   ├── data/message.dart                 # 修改：新增 isSystem getter
│   └── view/
│       ├── chat_page.dart                # 修改：右上角按钮 + isGroup/peerUserId/onAddMember 参数
│       ├── bubble/message_bubble.dart    # 修改：系统消息居中灰色标签样式
│       └── private_chat_info_page.dart   # 新建：单聊详情页
├── flash_im_friend/lib/src/
│   └── view/friend_list_page.dart        # 修改：新增群聊回调参数
├── flash_im_friend/lib/
│   └── flash_im_friend.dart              # 修改：导出 pinyin_helper.dart

client/lib/src/
└── home/view/home_page.dart              # 修改：WxPopupMenuButton 弹出菜单 + 群聊入口
```


### 职责划分

```
View (页面/组件)
  ↓ 用户交互
Cubit (状态管理)
  ↓ 业务逻辑
Repository (数据访问)
  ↓ HTTP / WS
后端 API / WsClient
```

- `CreateGroupPage`：微信风格选人页，放在 `flash_im_group` 模块。接收 `SelectableMember` 列表（含 letter 字段）和 `initialSelectedIds`。返回 `CreateGroupResult`，不直接调 API
- `MyGroupsPage`：放在 `flash_im_group` 模块。加载已加入的群聊列表（`getList(type: 1)`），顶部 FlashSearchBar 本地过滤搜索，点击群聊跳转 ChatPage
- `PrivateChatInfoPage`：StatelessWidget，显示对方信息 + "+"按钮

### 技术决策

| 决策 | 方案 | 理由 |
|------|------|------|
| CreateGroupPage 放哪个模块 | flash_im_group | 群聊是独立域，和 im-friend 独立的理由一样。后续群管理页面也放这里 |
| CreateGroupPage 的好友数据来源 | 由调用方传入 `List<SelectableMember>`（含 letter 字段） | 避免 flash_im_group 依赖 flash_im_friend，letter 由调用方用 PinyinUtil 计算 |
| 群名自动拼接 | 前端拼接成员昵称（≤3 人全拼，>3 人前三 + "等"），传给后端 | 不改后端，群名仍是必填字段 |
| 通讯录"群聊"入口 | MyGroupsPage（群聊列表 + 搜索） | 替代原来的"搜索群聊"直接跳搜索页，更符合微信交互 |
| 单聊详情页放哪个模块 | flash_im_chat | 它是 ChatPage 的子页面，且参考项目也放在 im_chat 中 |
| 宫格头像 | GroupAvatarWidget 解析 grid: 前缀渲染九宫格 | 参照参考项目 GroupAvatar 组件，放在 flash_shared |
| 系统消息样式 | sender_id=999999999 时居中灰色标签 | 参照参考项目 _buildSystemMessage |
| 右上角菜单 | WxPopupMenuButton 弹出尖角气泡 | 微信风格，放在 flash_shared 通用组件 |
| ConversationListCubit 修复 | _handleUpdate 保留 avatar 字段 | 群聊收到新消息后 avatar 不丢失 |

### 第三方依赖

| 依赖 | 用途 | 已有/需新增 |
|------|------|-----------|
| flutter_bloc | 状态管理 | 已有 |
| dio | HTTP 请求 | 已有 |
| equatable | 值对象比较 | 已有 |

无需新增第三方依赖。

## 6. 验收标准

| 验收条件 | 验收方式 |
|----------|----------|
| 编译通过 | `flutter analyze` 无错误 |
| 创建群聊：选 2+ 好友 → 自动拼接群名 → 创建成功 → 跳转群聊页 | 手动操作 |
| 创建群聊页：字母索引分组 + 搜索过滤 + 已选头像横条 | 手动操作 |
| 从单聊详情页发起群聊：对方预选中 → 再选好友 → 创建成功 | 手动操作 |
| 群聊消息：群成员发消息，其他成员收到并显示发送者昵称 | 手动操作（多设备/多用户） |
| 会话列表：群聊显示群名称和默认群图标 | 手动操作 |
| 我的群聊：通讯录"群聊"入口 → 显示已加入群聊列表 → 点击进入群聊 | 手动操作 |
| 我的群聊搜索：输入关键词本地过滤已加入的群 | 手动操作 |
| ChatPage 右上角：单聊显示"..."可进入详情页，群聊显示群图标 | 手动操作 |

## 7. 暂不实现

| 功能 | 理由 |
|------|------|
| 群详情页（群信息/成员列表/群设置） | 属于群管理域，下一章 |
| 群聊消息预览拼接发送者昵称 | 后端 generate_preview 不拼接昵称，与参考项目一致 |
| @提醒 | 依赖群成员列表，进阶功能 |
| 群消息已读回执 | 复杂度高，进阶功能 |
