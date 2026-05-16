# IM 测试基础设施 + ChatCubit 拆分 — 功能分析

## 概述

本版本不新增用户功能，而是进行工程治理：为 IM 聊天模块搭建单元测试基础设施，然后在测试保护下将 772 行的 ChatCubit 拆分为职责单一的 mixin 结构。目标是"虫害不生"——通过测试固定行为，通过拆分降低后续维护成本。

## 一、交互链

本次无用户交互变更。治理完成后，用户体验应与治理前完全一致。

验证标准：以下 14 个场景在治理前后行为不变。

| # | 场景 | 验证方式 |
|---|------|---------|
| 1 | 文本消息发送 | 发一条，对方收到，本方显示已发送 |
| 2 | 图片发送 | 选图发送，显示进度，对方看到图 |
| 3 | 视频发送 | 选视频发送，显示进度，对方能播放 |
| 4 | 文件发送 | 选文件发送，显示进度，对方能下载 |
| 5 | 文件下载 | 点击对方文件，下载成功可打开 |
| 6 | 消息撤回 | 撤回一条，双方显示"撤回了一条消息" |
| 7 | 置顶消息 | 置顶一条，顶部栏显示；取消后消失 |
| 8 | 多选删除 | 长按进入多选，勾选删除，消息消失 |
| 9 | 引用回复 | 滑动引用，发送后显示引用卡片 |
| 10 | 转发 | 转发到另一个会话，对方收到 |
| 11 | 已读回执 | 进入聊天后对方看到已读标记 |
| 12 | 发送超时 | 断网发消息，10 秒后显示失败 |
| 13 | 加载更多 | 上拉加载历史消息 |
| 14 | 接收消息 | 对方发来消息，实时显示在列表中 |

## 二、逻辑树

### 事件流：ChatCubit 核心生命周期

| 时刻 | 事件 | 处理 | 产生的新事件 |
|------|------|------|-------------|
| T0 | ChatCubit 创建 | 订阅 WS 的 chatMessage/ack/recalled/pinChanged/readReceipt 流 | — |
| T1 | loadMessages 调用 | Repository 获取消息 → 排序 → emit ChatLoaded | 触发 loadReadSeq + loadPinnedMessages |
| T2 | 用户输入文本并发送 | 创建本地消息 → emit → WS 发送 → 启动 10s 超时 | 等待 ACK |
| T3a | 收到 ACK | 替换本地 ID 为服务端 ID → 写入缓存 | — |
| T3b | 超时未收到 ACK | 标记消息为 failed | — |
| T4 | 收到对方消息 | 解析 → 去重 → 插入列表 → 上报已读 | — |
| T5 | 用户撤回消息 | HTTP 请求 → 本地替换为撤回文案 → 更新缓存 | — |
| T6 | ChatCubit close | 取消所有 StreamSubscription | — |

### 状态流转

| 实体 | 触发事件 | 前状态 | 后状态 |
|------|---------|--------|--------|
| ChatState | loadMessages | ChatInitial | ChatLoading → ChatLoaded |
| Message（本地） | sendMessage | — | status=sending |
| Message（本地） | 收到 ACK | status=sending | status=sent, id=服务端ID |
| Message（本地） | 超时 | status=sending | status=failed |
| Message | recallMessage | status=sent | content="撤回了一条消息" |
| ChatLoaded | enterMultiSelect | isMultiSelect=false | isMultiSelect=true |

## 三、功能编号与网络定位

### 本次新增节点

| 编号 | 功能节点 | 层级 | 简介 |
|------|---------|------|------|
| I-10 | IM 测试 Mock 层 | 基础设施 | MockMessageRepository / MockWsClient / MockLocalStore |
| I-11 | ChatCubit 单元测试 | 基础设施 | 覆盖 14 个核心场景的自动化测试 |
| I-12 | ChatCubit Mixin 拆分 | 基础设施 | ChatFileMixin / ChatPinMixin / ChatSelectMixin |

### 前置依赖

| 依赖节点 | 依赖方式 | 是否已有 |
|----------|---------|---------|
| MessageRepository 接口 | mock 其方法 | ✅ 已有（具体类） |
| WsClient stream | 用 StreamController 模拟 | ✅ 已有 |
| LocalStore 接口 | mock 或内存实现 | ✅ 已有（抽象类） |
| ChatState / Message 模型 | 测试中构造实例 | ✅ 已有 |

### 边界接口

| 接口 | 定义方 | 消费方 | 说明 |
|------|--------|--------|------|
| MessageRepository | flash_im_chat | ChatCubit + 测试 | 需要可 mock（当前是具体类，需抽接口或用 mockito） |
| WsClient | flash_im_core | ChatCubit + 测试 | stream 可通过 StreamController 注入 |
| LocalStore | flash_im_cache | ChatCubit + 测试 | 已是抽象类，可直接 mock |

## 四、结论

### 开发顺序

1. **搭建 Mock 层**：为 MessageRepository 抽取接口（或用 mockito 生成 mock），为 WsClient 创建测试用的 FakeWsClient
2. **写 ChatCubit 单元测试**：覆盖 14 个场景，固定当前行为
3. **执行 Mixin 拆分**：在测试保护下搬代码
4. **跑测试验证**：全部通过 = 行为一致

### 复杂度集中的地方

- MessageRepository 是具体类，没有抽象接口。需要决定：抽接口 vs 用 mockito 的 `@GenerateMocks`
- WsClient 的多个 stream（chatMessageStream、messageAckStream 等）需要在测试中精确控制时序
- 消息发送的"本地消息 → ACK 确认 → 替换 ID"流程涉及异步时序，测试需要用 `fakeAsync` 或手动控制

### 暂不实现的部分

- 集成测试（需要真实后端）：本次只做单元测试
- 其他大文件（home_page、group_chat_info_page）的拆分：等后续版本
