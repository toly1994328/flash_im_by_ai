# 本地缓存 — 客户端局域网络

涉及节点：I-14, D-39, F-15~F-16, F-18, P-74~P-75

---

## 一、远景：模块与依赖

### 涉及模块

| 模块 | 位置 | 职责 |
|------|------|------|
| flash_im_cache | client/modules/flash_im_cache | 本地数据库 + 抽象接口 + drift 实现 + 同步引擎 + 文件缓存管理器 |
| flash_im_cache_drift | client/modules/flash_im_cache_drift | drift 具体实现（DAO、表定义、迁移） |
| flash_im_chat | client/modules/flash_im_chat | 聊天逻辑层消费 FileCacheManager，气泡优先本地渲染 |
| im-message | server/modules/im-message | 新增 after_seq 参数（后端唯一改动） |

### 依赖关系

```mermaid
graph TD
    CACHE[flash_im_cache] --> CORE[flash_im_core]
    CACHE --> DRIFT[drift + sqlite3_flutter_libs]
    CACHE --> DIO[dio]
    CACHE --> PATH[path]
    CONV[flash_im_conversation] --> CACHE
    CHAT[flash_im_chat] --> CACHE
    FRIEND[flash_im_friend] --> CACHE
    CACHE -.->|after_seq 增量同步| MSG[im-message]
    CHAT -->|FileCacheManager| CACHE
    MAIN[main.dart] -->|globalFileCacheManager| CACHE
```

### 节点详情

| 编号 | 功能节点 | 模块 | 职责 |
|------|---------|------|------|
| I-14 | 本地数据库 | flash_im_cache_drift | drift + SQLite，per-user 数据库，3 张缓存表 + localData 列 |
| F-15 | LocalStore | flash_im_cache/local_store | 本地存储抽象接口，定义读写契约 + updateLocalData/getLocalData |
| F-16 | SyncEngine | flash_im_cache/sync_engine | WS 事件写入本地 + 重连增量同步 + 回调通知 |
| F-18 | 文件缓存管理器 | flash_im_cache/file_cache_manager | 下载队列(max=3) + URL 去重 + 本地路径持久化 + markLocal |
| D-39 | 增量消息查询 | im-message/routes | GET /messages 新增 after_seq 参数 |
| P-74 | 桌面端文件操作菜单 | flash_im_chat/desktop_context_menu | 右键「另存为」「打开文件夹」 |
| P-75 | 发送大小限制 | flash_im_chat/chat_file_mixin | 图片/视频/文件 ≤ 50MB，音频 ≤ 2min |

---

## 二、中景：数据通道与事件流

### 数据通道

| 通道 | 协议 | 方向 | 特点 |
|------|------|------|------|
| Repository → LocalStore | 内存 | 客户端内部 | 读取优先本地，空数据 fallback HTTP |
| SyncEngine → LocalStore | 内存 | 客户端内部 | WS 事件实时写入 + 重连批量同步 |
| SyncEngine → 服务端 | HTTP | 客户端主动 | 增量同步用 after_seq，全量同步用 limit |
| SyncEngine → Cubit | 回调 | 客户端内部 | 同步完成后通知 UI 刷新 |
| WsClient → SyncEngine | Stream | 客户端内部 | 5 个事件流（state/chat/conv/friend+/friend-） |
| FileCacheManager → LocalStore | 内存 | 客户端内部 | 下载完成写 localData，读取时检查缓存 |
| FileCacheManager → Dio | HTTP | 客户端主动 | 注入的 DownloadFunction，实际下载文件 |
| ChatCubit → FileCacheManager | 内存 | 客户端内部 | loadMessages 后触发自动缓存，下载完更新 state |

### 关键事件流：冷启动

```mermaid
sequenceDiagram
    participant M as main.dart
    participant SE as SyncEngine
    participant WS as WsClient
    participant CB as Cubit
    participant R as Repository
    participant DB as SQLite
    participant API as 服务端

    M->>DB: T1: initCache → 打开数据库
    M->>SE: T2: SyncEngine.start()
    M->>WS: T3: wsClient.connect()
    CB->>R: T4: loadConversations()
    R->>DB: T5: 读本地
    DB-->>CB: 立即展示
    WS-->>SE: T6: authenticated
    SE->>API: T7: GET /conversations
    SE->>DB: T8: syncConversations
    SE->>CB: T9: onConversationChanged
    CB->>R: T10: reload
```

### 关键事件流：重连同步

```mermaid
sequenceDiagram
    participant SE as SyncEngine
    participant API as 服务端
    participant DB as LocalStore
    participant CB as Cubit

    SE->>API: T1: GET /conversations
    SE->>DB: T2: syncConversations
    SE->>CB: T3: onConversationChanged
    SE->>API: T4: GET /api/friends
    SE->>DB: T5: syncFriends
    SE->>CB: T6: onFriendListChanged
    loop T7: 每个有缓存的会话
        SE->>API: GET /messages?after_seq=maxSeq
        SE->>DB: cacheMessages
    end
```

### 边界接口

**HTTP 接口**

| 接口 | 提供节点 | 消费节点 |
|------|---------|---------|
| GET /messages?after_seq=N | D-39 | F-16 (SyncEngine) |
| GET /conversations | D-02 | F-16 (SyncEngine) |
| GET /api/friends | D-15 | F-16 (SyncEngine) |

**回调接口**

| 回调 | 定义节点 | 消费节点 |
|------|---------|---------|
| onConversationChanged | F-16 (SyncEngine) | ConversationListCubit |
| onFriendListChanged | F-16 (SyncEngine) | FriendCubit |
| onMessagesChanged | F-16 (SyncEngine) | （预留） |

---

## 三、近景：生命周期与订阅

### 核心对象生命周期

| 对象 | 创建时机 | 销毁时机 | 生命跨度 |
|------|---------|---------|---------|
| DriftLocalStore | initCache（登录后） | 退出登录 | 应用级 |
| SyncEngine | initCache（登录后） | 退出登录 | 应用级 |
| FileCacheManagerImpl | initCache（登录后） | 退出登录 | 应用级 |
| AppDatabase | DriftLocalStore.open | DriftLocalStore.dispose | 应用级 |

### 订阅关系

| 订阅者 | 监听目标 | 订阅时机 | 取消时机 | 是否成对 |
|--------|---------|---------|---------|---------|
| SyncEngine | WsClient.stateStream | start() | dispose() | ✅ |
| SyncEngine | WsClient.chatMessageStream | start() | dispose() | ✅ |
| SyncEngine | WsClient.conversationUpdateStream | start() | dispose() | ✅ |
| SyncEngine | WsClient.friendAcceptedStream | start() | dispose() | ✅ |
| SyncEngine | WsClient.friendRemovedStream | start() | dispose() | ✅ |

---

## 四、版本演进

| 版本 | 变更 |
|------|------|
| v0.0.1_cache | 初始版本：drift 建表 + LocalStore 接口 + DriftLocalStore + SyncEngine + Repository 改造 |
| v0.33.0 | 文件缓存机制：FileCacheManager（下载队列+并发+URL去重）+ localData 持久化 + 图片/音频/视频封面自动缓存 + 桌面端右键操作 + 发送大小限制 |
