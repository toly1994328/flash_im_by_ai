---
module: im-search + im-chat + im-group
version: v0.0.1_search
date: 2026-04-26
tags: [综合搜索, 会话内搜索, Flutter]
---

# 综合搜索 — 客户端设计报告

> 关联设计：[服务端设计](../server/design.md) | [功能分析](../analysis.md)

## 1. 目标

- 新建 flash_im_search 模块：SearchRepository + SearchCubit + SearchPage + MessageDetailPage
- SearchPage：综合搜索页，三个 API 并发调用，结果分区展示（联系人/群聊/聊天记录）
- MessageDetailPage：某会话的匹配消息列表，点击跳转 ChatPage
- ConversationSearchPage：会话内搜索页，从聊天详情页进入
- SingleMessagePage：单条消息详情页，从会话内搜索点击进入
- 搜索历史本地存储（SharedPreferences）
- 关键词高亮（HighlightText 组件）
- 单聊详情页 + 群聊详情页新增"查找聊天内容"入口
- 消息 Tab + 通讯录 Tab 顶部搜索栏跳转综合搜索
- 搜索输入框统一使用 FlashSearchInput 组件

## 2. 现状分析

### 已有能力

- `FlashSearchBar` / `FlashSearchInput`（flash_shared）：通用搜索栏组件
- `UserSearchPage`（flash_im_friend）：搜索用户（添加好友场景）
- `SearchGroupPage`（flash_im_group）：搜索群聊（搜索加群场景）
- `PrivateChatInfoPage`（flash_im_chat）：单聊详情页
- `GroupChatInfoPage`（flash_im_group）：群聊详情页

### 缺失

- 无综合搜索页（搜好友 + 搜已加入群 + 搜消息）
- 无消息搜索结果展示
- 无会话内搜索
- 无搜索历史
- 无关键词高亮

## 3. 核心流程

### 综合搜索数据流

```
用户输入关键词
  → SearchCubit 300ms 防抖
  → Future.wait 并发三个 API
  → SearchSuccess / SearchPartialSuccess
  → SearchPage 分区渲染（联系人 / 群聊 / 聊天记录）
  → 点击联系人 → onFriendTap 回调
  → 点击群聊 → onGroupTap 回调
  → 点击聊天记录 → 1条匹配直接跳转 / 多条匹配进入 MessageDetailPage
```

### 会话内搜索数据流

```
聊天详情页 → "查找聊天内容"
  → ConversationSearchPage
  → 输入关键词 → 300ms 防抖
  → GET /conversations/{id}/messages/search
  → 消息列表展示（高亮关键词）
  → 点击消息 → onMessageTap 回调（传 conversationId + messageId）
```

## 4. 项目结构与技术决策

### 新建模块

```
client/modules/flash_im_search/
├── lib/
│   ├── flash_im_search.dart          # barrel export
│   └── src/
│       ├── data/
│       │   ├── search_models.dart    # 数据模型
│       │   └── search_repository.dart # API 封装
│       ├── logic/
│       │   ├── search_cubit.dart     # 综合搜索状态管理
│       │   └── search_state.dart     # 状态定义
│       └── view/
│           ├── search_page.dart      # 综合搜索页
│           ├── message_detail_page.dart # 消息搜索详情页
│           ├── conversation_search_page.dart # 会话内搜索页
│           ├── single_message_page.dart  # 单条消息详情页
│           └── widgets/
│               ├── highlight_text.dart    # 关键词高亮
│               ├── friend_search_item.dart  # 好友搜索结果项
│               ├── group_search_item.dart   # 群聊搜索结果项
│               └── message_search_item.dart # 消息搜索结果项
└── pubspec.yaml
```

### 修改文件

```
client/modules/flash_im_chat/lib/src/view/
├── chat_page.dart                    # 新增 onSearchChat 回调
└── private_chat_info_page.dart       # 新增"查找聊天内容"入口

client/modules/flash_im_group/lib/src/view/
└── group_chat_info_page.dart         # 新增"查找聊天内容"入口

client/modules/flash_im_friend/lib/src/view/
└── friend_list_page.dart             # 新增搜索栏（onSearchTap 回调）

client/modules/flash_shared/lib/src/
└── search_input.dart                 # 新增 backgroundColor 参数

client/lib/src/home/view/
└── home_page.dart                    # 消息 Tab + 通讯录 Tab 搜索栏 + _openSearch + _openChatById

client/lib/
└── main.dart                         # 新增 SearchRepository 到 RepositoryProvider
```

### 技术决策

| 决策 | 方案 | 理由 |
|------|------|------|
| 新建独立模块 | flash_im_search | 搜索是横切功能，不属于任何已有模块 |
| SearchCubit 300ms 防抖 | Timer + cancel | 避免每次按键都发请求 |
| 三个 API 并发 + 部分失败容忍 | Future.wait + 各自 try-catch | 好友搜索失败不阻塞群聊和消息搜索 |
| 搜索历史 SharedPreferences | 本地存储，最多 20 条 | 不需要同步到服务端 |
| 关键词高亮 | HighlightText 组件，RichText + TextSpan | 匹配部分用主题蓝标记 |
| 搜索结果每区默认 3 条 | 点击"查看更多"展开全部 | 避免首屏太长 |
| 会话内搜索独立页面 | ConversationSearchPage | 不复用 SearchPage，逻辑更简单 |
| MessageDetailPage 分页加载 | 进入时调会话内搜索 API，每页 20 条，滚动加载更多 | 综合搜索只返回每组 3 条预览，详情页需要完整列表 |
| 导航用回调 | onFriendTap / onGroupTap / onMessageTap | 搜索模块不依赖具体的页面路由 |
| 会话内搜索点击 → 消息详情页 | SingleMessagePage 展示完整消息信息 | 本来就在会话里，不需要跳 ChatPage |
| 综合搜索点击 → 直接 push | 不 pop 搜索页，push 到栈顶 | 避免 pop + push 动画冲突 |
| 搜索输入框 | 统一使用 FlashSearchInput（flash_shared） | 样式一致，支持自定义背景色 |

### 第三方依赖

- `shared_preferences`（已有）：搜索历史存储

## 5. 验收标准

| 验收条件 | 验收方式 |
|----------|----------|
| 编译通过 | `flutter analyze` 无错误 |
| 综合搜索：输入关键词后分区展示结果 | 手动操作 |
| 综合搜索：点击联系人跳转好友详情 | 手动操作 |
| 综合搜索：点击群聊跳转 ChatPage | 手动操作 |
| 综合搜索：点击聊天记录跳转 ChatPage 或 MessageDetailPage | 手动操作 |
| 综合搜索：搜索历史显示和清除 | 手动操作 |
| 综合搜索：关键词高亮 | 手动操作 |
| 会话内搜索：从聊天详情页进入 | 手动操作 |
| 会话内搜索：搜索结果列表 | 手动操作 |
| 会话内搜索：点击消息进入消息详情页 | 手动操作 |
| 通讯录搜索栏：点击跳转综合搜索 | 手动操作 |

## 6. 暂不实现

| 功能 | 理由 |
|------|------|
| 搜索结果分页 | 每个分区最多 20 条，不需要分页 |
| 搜索建议/联想 | 本版不做 |
| 消息定位（滚动到指定 seq） | 需要 ChatPage 支持 scrollToMessage，后续版本实现 |
