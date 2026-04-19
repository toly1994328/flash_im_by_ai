# 群聊 — 前端局域网络

涉及节点：P-28~P-29, P-31~P-37, F-10

---

## 一、远景：模块与依赖

### 涉及模块

| 模块 | 位置 | 职责 |
|------|------|------|
| flash_im_group | client/modules/flash_im_group/ | 群聊页面和数据（独立模块） |
| flash_im_chat | client/modules/flash_im_chat/ | 单聊详情页 + ChatPage 适配 |
| flash_im_conversation | client/modules/flash_im_conversation/ | 会话列表 type 过滤 + 宫格头像适配 |
| flash_shared | client/modules/flash_shared/ | GroupAvatarWidget + WxPopupMenuButton |
| flash_im_core | client/modules/flash_im_core/ | WsClient groupJoinRequestStream（GROUP_JOIN_REQUEST 帧分发） |

### 依赖关系

```mermaid
graph LR
    HP[home_page.dart] --> FIG[flash_im_group]
    HP --> FIC[flash_im_conversation]
    HP --> FICH[flash_im_chat]
    HP --> FIF[flash_im_friend]
    FIG --> FS[flash_shared]
    FIG --> FIC
    FIG --> FB[flutter_bloc]
    FIG --> FIMC[flash_im_core]
    FICH --> FS

    style FIG fill:#E8F5E9,stroke:#4CAF50
    style FIC fill:#E3F2FD,stroke:#2196F3
    style FICH fill:#E8F5E9,stroke:#4CAF50
    style FS fill:#F3E5F5,stroke:#9C27B0
    style FIF fill:#E8F5E9,stroke:#4CAF50
    style FIMC fill:#FFF8E1,stroke:#FFC107
```

flash_im_group 依赖 flash_shared（共享组件）、flash_im_conversation（Conversation 模型 + ConversationRepository）、flash_im_core（WsClient groupJoinRequestStream）和 flutter_bloc（GroupNotificationCubit）。不依赖 flash_im_friend——好友数据通过 home_page 转换为 SelectableMember 传入。

### 节点详情

| 编号 | 功能节点 | 模块 | 职责 |
|------|---------|------|------|
| F-10 | 群通知WS帧分发 | flash_im_core | WsClient 新增 GROUP_JOIN_REQUEST 帧类型，groupJoinRequestStream 分发 |
| P-28 | 创建群聊页 | flash_im_group | 微信风格选人 + 字母索引 + 自动群名 |
| P-29 | 我的群聊页 | flash_im_group | 群聊列表 + 本地搜索 |
| P-31 | 单聊详情页 | flash_im_chat | 对方信息 + 邀请更多人 |
| P-32 | 群聊消息气泡适配 | flash_im_chat | 系统消息居中灰色标签 |
| P-33 | 群聊会话列表适配 | flash_im_conversation | 宫格头像 + 默认群图标 |
| P-34 | 群搜索与入群 | flash_im_group | SearchGroupPage，独立搜索群聊页：远程搜索 + 四种按钮状态 + 入群对话框 |
| P-35 | 群通知页 | flash_im_group | GroupNotificationsPage，群主查看和处理入群申请列表 |
| P-36 | 群通知角标 | flash_im_group | GroupNotificationCubit 管理 pendingCount，驱动通讯录 Tab 红点 |
| P-37 | 群聊详情页 | flash_im_group | GroupChatInfoPage，展示群成员网格 + 群主可切换入群验证开关 |

---

## 二、中景：数据通道与事件流

### 数据通道

| 通道 | 协议 | 方向 | 特点 |
|------|------|------|------|
| GroupRepository.createGroup | HTTP | 客户端 → POST /groups | 创建群聊 |
| ConversationRepository.getList | HTTP | 客户端 → GET /conversations?type=1 | 群聊列表 |
| GroupRepository.searchGroups | HTTP | 客户端 → GET /groups/search?keyword= | 远程搜索群聊 |
| GroupRepository.joinGroup | HTTP | 客户端 → POST /groups/{id}/join | 入群申请（分支：直接加入/创建申请） |
| GroupRepository.handleJoinRequest | HTTP | 客户端 → POST /groups/{id}/join-requests/{rid}/handle | 群主审批 |
| GroupRepository.getJoinRequests | HTTP | 客户端 → GET /groups/join-requests | 群主查询入群通知 |
| GroupRepository.getGroupDetail | HTTP | 客户端 → GET /groups/{id}/detail | 群详情（成员列表+群信息） |
| GroupRepository.updateGroupSettings | HTTP | 客户端 → PUT /groups/{id}/settings | 群主切换入群验证 |
| WsClient.groupJoinRequestStream | WS | 服务端 → 客户端 | GROUP_JOIN_REQUEST 帧实时推送 |
| onCreated 回调 | 内存 | CreateGroupPage → home_page | 选人结果传递 |
| Friend → SelectableMember | 内存 | home_page 转换 | 模块解耦 |

### 关键事件流：创建群聊

```mermaid
sequenceDiagram
    participant U as 用户
    participant HP as home_page
    participant CGP as CreateGroupPage
    participant GR as GroupRepository
    participant API as POST /groups

    U->>HP: 点击发起群聊
    HP->>HP: Friend → SelectableMember
    HP->>CGP: push（传入 members + onCreated）
    U->>CGP: 选人 + 点击完成
    CGP->>HP: onCreated（CreateGroupResult）
    HP->>GR: createGroup
    GR->>API: POST /groups
    API-->>GR: Conversation
    HP->>HP: pushReplacement ChatPage
```

### 关键事件流：搜索并入群

```mermaid
sequenceDiagram
    participant U as 用户
    participant SGP as SearchGroupPage
    participant GR as GroupRepository
    participant API as im-group

    U->>SGP: 输入关键词（300ms 防抖）
    SGP->>GR: searchGroups(keyword)
    GR->>API: GET /groups/search?keyword=xxx
    API-->>GR: GroupSearchResult[]
    GR-->>SGP: 渲染搜索结果（四种按钮状态）

    U->>SGP: 点击加入/申请
    SGP->>GR: joinGroup(id, message?)
    GR->>API: POST /groups/{id}/join
    alt auto_approved: true
        API-->>GR: 直接加入成功
        SGP->>U: Toast "已成功加入群聊"
    else auto_approved: false
        API-->>GR: 申请已创建
        SGP->>U: Toast "申请已发送，等待群主审批"
    end
```

### 关键事件流：群主审批

```mermaid
sequenceDiagram
    participant WS as WsClient
    participant GNC as GroupNotificationCubit
    participant GNP as GroupNotificationsPage
    participant GR as GroupRepository
    participant API as im-group

    WS->>GNC: groupJoinRequestStream 推送
    GNC->>GNC: pendingCount++（驱动红点角标）

    GNP->>GR: getJoinRequests()
    GR->>API: GET /groups/join-requests
    API-->>GR: JoinRequestItem[]
    GR-->>GNP: 渲染申请列表

    GNP->>GR: handleJoinRequest(id, rid, approved)
    GR->>API: POST /groups/{id}/join-requests/{rid}/handle
    API-->>GR: 处理结果
    GNP->>GNP: 更新申请状态（已同意/已拒绝）
```

### 边界接口

**HTTP 接口**

| 接口 | 消费节点 | 提供节点 |
|------|---------|---------|
| POST /groups | P-28（via GroupRepository） | D-18 |
| GET /conversations?type=1 | P-29（via ConversationRepository） | D-02 |
| GET /groups/search?keyword= | P-34（via GroupRepository） | D-19 |
| POST /groups/{id}/join | P-34（via GroupRepository） | D-20 |
| POST /groups/{id}/join-requests/{rid}/handle | P-35（via GroupRepository） | D-21 |
| GET /groups/join-requests | P-35（via GroupRepository） | D-22 |
| GET /groups/{id}/detail | P-37（via GroupRepository） | D-23 |
| PUT /groups/{id}/settings | P-37（via GroupRepository） | D-23 |

**WS 流**

| 流 | 消费节点 | 来源 |
|----|---------|------|
| groupJoinRequestStream | P-36（GroupNotificationCubit） | F-10（WsClient） |

**Protobuf 消息**

| 消息 | 解码模块 | 消费模块 |
|------|---------|---------|
| GroupJoinRequestNotification | flash_im_core (WsClient) | flash_im_group (GroupNotificationCubit) |

---

## 三、近景：生命周期与订阅

### 核心对象生命周期

| 对象 | 创建时机 | 销毁时机 | 生命跨度 |
|------|---------|---------|---------|
| GroupRepository | main.dart 启动时 | 应用退出 | 应用级 |
| GroupNotificationCubit | home_page 创建时 | home_page 销毁时 | 应用级 |
| CreateGroupPage | push 进入 | pushReplacement 替换 | 页面级 |
| MyGroupsPage | push 进入 | pop 返回 | 页面级 |
| SearchGroupPage | push 进入 | pop 返回 | 页面级 |
| GroupNotificationsPage | push 进入 | pop 返回 | 页面级 |
| GroupChatInfoPage | push 进入 | pop 返回 | 页面级 |

### GroupNotificationCubit 生命周期与 WS 订阅

GroupNotificationCubit 在 home_page 创建时初始化，订阅 WsClient.groupJoinRequestStream。每收到一条 GROUP_JOIN_REQUEST 帧，pendingCount 自增，驱动通讯录 Tab 红点角标更新。进入 GroupNotificationsPage 时通过 HTTP 拉取完整列表，处理申请后 pendingCount 递减。Cubit 销毁时自动 cancel StreamSubscription。

---

## 四、版本演进

| 版本 | 变更 |
|------|------|
| v0.0.1_group | 新建 flash_im_group 模块；CreateGroupPage 微信风格选人；MyGroupsPage 群聊列表；PrivateChatInfoPage 单聊详情；ChatPage/ConversationTile/MessageBubble 群聊适配 |
| v0.0.2_group | 新增 F-10, P-34~P-37：SearchGroupPage 搜索群聊页（远程搜索+四种按钮状态+入群对话框）；GroupNotificationsPage 群通知页；GroupNotificationCubit 群通知角标（WS 驱动 pendingCount）；GroupChatInfoPage 群聊详情页（成员网格+入群验证开关）；flash_im_core 扩展 groupJoinRequestStream；新增 flutter_bloc 依赖 |
