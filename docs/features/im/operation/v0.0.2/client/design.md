---
module: flash_im_chat + flash_im_core + flash_im_conversation
version: v0.0.2_operation
date: 2026-05-08
tags: [消息转发, @提及, 消息置顶, 会话选择器, PIN_CHANGED]
---

# 消息转发与@提及与置顶 — 客户端设计报告

> 关联设计：[功能分析](../analysis.md) · [服务端设计](../server/design.md)

## 1. 目标

- 消息转发：单条转发，通过会话选择器选择目标（支持单选/多选切换）
- 会话选择器：复用 MemberPickerPage，展示最近会话，支持搜索
- @提及输入：群聊输入框检测 @ 字符 → 弹出成员选择浮层 → 插入 @昵称 文本 → 构建 mentions 数组
- @提及展示：消息气泡中 @文本 蓝色高亮（RichText）+ 会话列表红色「有人@我」前缀
- 消息置顶：ChatPage 顶部置顶消息栏 + 置顶/取消置顶操作 + PIN_CHANGED 帧监听
- 长按菜单扩展：新增"转发"和"置顶"选项
- 多选模式扩展：底部新增"转发"按钮

## 2. 现状分析

### 已有能力

- 长按菜单（MessageActionMenu）已实现，支持动态菜单项过滤
- 多选模式已实现（isMultiSelect + selectedIds + 底部操作栏）
- ChatCubit 管理消息状态，有完整的 WS 帧监听机制
- WsClient 有帧分发机制（StreamController.broadcast）
- flash_im_cache 有 LocalStore 接口
- MessageRepository 有 HTTP 请求封装
- 群成员查询已有（GroupRepository.getMembers）

### 缺失

- 没有会话选择器页面
- WsClient 没有 pinChangedStream
- ChatInput 没有 @ 检测和成员选择浮层
- MessageBubble 没有 @文本高亮渲染
- ChatPage 没有置顶消息栏
- 会话列表没有"有人@我"标识

## 3. 数据模型与接口

### 客户端数据模型

**ChatState 扩展**：

| 字段 | 类型 | 说明 |
|------|------|------|
| pinnedMessages | List\<PinnedMessage\> | 当前会话的置顶消息列表 |

**新增模型**：

```dart
class PinnedMessage {
  final String pinId;
  final String messageId;
  final String content;
  final int msgType;
  final String senderName;
  final int pinnedBy;
  final DateTime pinnedAt;
}

class MentionInfo {
  final String userId;
  final int offset;
  final int length;
}
```

**extra.mentions 格式**：

```json
{
  "mentions": [
    {"user_id": "1", "offset": 0, "length": 4},
    {"user_id": "all", "offset": 5, "length": 4}
  ]
}
```

### 接口调用

| 接口 | 调用方 | 说明 |
|------|--------|------|
| POST /messages/forward | ChatCubit | 转发消息 |
| POST /messages/pin | ChatCubit | 置顶消息 |
| DELETE /messages/pin/{id} | ChatCubit | 取消置顶 |
| GET /messages/pinned | ChatCubit | 加载置顶列表 |

## 4. 核心流程

### 转发流程

用户长按 → 点击转发 → 打开会话选择器 → 选择目标 → 确认 → HTTP POST → 目标会话收到消息。

### @提及流程

用户输入 @ → 检测到 @ 字符 → 弹出成员浮层 → 选择成员 → 插入 @昵称 文本 + 记录 offset/length → 发送时构建 extra.mentions。

### 置顶流程

群主长按 → 点击置顶 → HTTP POST → 收到 PIN_CHANGED 帧 → ChatPage 顶部出现置顶栏。

## 5. 项目结构与技术决策

### 文件结构

```
flash_im_chat/lib/src/
├── data/
│   └── message_repository.dart   # 修改：新增 forwardMessage、pinMessage、unpinMessage、getPinned
├── logic/
│   └── chat_cubit.dart           # 修改：新增转发/置顶方法 + pinnedMessages 状态
├── view/
│   ├── chat_page.dart            # 修改：置顶栏 + 菜单扩展
│   ├── chat_input.dart           # 修改：@ 检测 + 成员选择浮层
│   ├── message_action_menu.dart  # 修改：新增转发/置顶菜单项
│   ├── conversation_picker_page.dart  # 新建：会话选择器
│   ├── mention_picker.dart       # 新建：@成员选择浮层
│   ├── pinned_message_bar.dart   # 新建：置顶消息栏
│   └── bubble/
│       ├── message_bubble.dart   # 修改：@文本高亮
│       ├── text_bubble.dart      # 修改：RichText 渲染 mentions
│       └── forward_bubble.dart   # 新建：合并转发消息卡片
│   ├── forward_detail_page.dart  # 新建：合并转发展开详情页

flash_im_core/lib/src/logic/
│   └── ws_client.dart            # 修改：新增 pinChangedStream

flash_im_conversation/lib/src/
│   └── view/conversation_tile.dart  # 修改：@提示标识
```

### 职责划分

| 组件 | 职责 |
|------|------|
| ConversationPickerPage | 展示会话列表 + 好友列表，选择后返回目标 ID |
| MentionPicker | 浮层展示群成员列表，选择后回调 |
| PinnedMessageBar | 展示置顶消息摘要，点击跳转 |
| ForwardBubble | 合并转发消息的卡片展示，点击进入详情页 |
| ForwardDetailPage | 展开合并转发的原始消息列表（只读） |
| ChatCubit | 管理转发/置顶/@ 的业务逻辑 |
| TextBubble | 用 RichText 渲染 @高亮 |

### 技术决策

| 决策 | 方案 | 理由 |
|------|------|------|
| 会话选择器 | 复用 MemberPickerPage（PickerSelectMode.single/multi 切换 + showIndexBar=false） | 统一选人组件，右上角切换单选/多选 |
| @检测 | TextEditingController.addListener 监听文本变化 | 检测最后输入的字符是否为 @ |
| @选择界面 | push MemberPickerPage（多选 + quickSelectIds 支持"所有人"快速返回） | 复用已有选人组件，@所有人点击直接返回 |
| @高亮 | RichText + TextSpan | 精确控制每段文字的样式 |
| @会话列表提示 | SyncEngine 检测 mentions + ConversationListCubit 维护 MentionMeRecord 列表 | 结构化记录，区分 @我/@所有人，优先显示 @我 |
| 置顶栏 | ChatPage 顶部固定 Widget + 点击展开下拉列表（SizeTransition 动画） | 参考项目风格，蓝色背景 + 分段指示器 |
| 置顶数据 | 进入聊天页时 GET /pinned 加载 | 不缓存到本地，每次进入实时查询 |
| PIN_CHANGED 监听 | ChatCubit 订阅 pinChangedStream | 实时更新置顶栏 |
| 转发确认 | 选择器内 onConfirmAsync 弹确认弹窗（含消息预览），确认后才 pop | 避免时序问题，用户看到预览再确认 |
| 消息缓存 | HTTP 拉取消息后写入 LocalStore | 下次进入从本地读取，不丢失历史 |
| MemberPickerPage 扩展 | 新增 selectMode / showIndexBar / quickSelectIds / onConfirmAsync / actions 参数 | 通用选人组件支持更多场景（转发、@提及） |

### 新增依赖

无新增外部依赖。

## 6. 验收标准

| 验收条件 | 验收方式 |
|----------|----------|
| 单条转发成功 | 长按 → 转发 → 选择会话 → 目标会话出现消息 |
| 多条合并转发 | 多选 → 转发 → 目标会话出现 FORWARD 卡片 |
| 会话选择器展示正确 | 最近会话 + 好友列表 |
| @输入触发浮层 | 群聊输入 @ → 成员列表弹出 |
| @选择后插入文本 | 选择成员 → 输入框出现 @昵称 |
| @高亮展示 | 收到含 mentions 的消息 → 蓝色高亮 |
| 会话列表@提示 | 被@后会话列表显示红色前缀 |
| 置顶成功 | 群主长按 → 置顶 → 顶部出现置顶栏 |
| 取消置顶 | 点击置顶栏× → 置顶栏消失 |
| PIN_CHANGED 实时 | 其他成员实时看到置顶变化 |
| flutter analyze 通过 | 零错误 |

## 7. 暂不实现

| 功能 | 理由 |
|------|------|
| 转发来源标注 | 当前版本转发后看起来是普通消息 |
| @推送通知 | 需要 FCM/APNs，当前只做会话列表红色提示 |
| 置顶消息跳转定位 | 需要 ScrollController 精确定位到 seq，复杂度高，后续版本做 |
| @所有人后端权限校验 | 前端控制（不显示选项），后端透传 |
