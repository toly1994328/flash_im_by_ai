---
module: im-group
version: v0.0.3
date: 2026-04-21
tags: [群聊, 成员管理, 踢人, 退群, 转让, 解散, 群公告, 群设置, Flutter]
---

# 群成员管理与群详情 — 客户端设计报告

> 关联设计：[服务端设计](../server/design.md) | [功能分析](../analysis.md) | [v0.0.2 客户端](../../v0.0.2/client/design.md)

## 1. 目标

- GroupChatInfoPage 大幅扩展：从最小版本（成员网格 + 入群验证开关）到完整版本（邀请/踢人/退群/群公告/群名编辑 + 转让/解散独立按钮）
- 新增 MemberPickerPage 通用选人组件：下沉到 flash_shared，支持邀请模式和移除模式（红色勾选）
- 新增 EditGroupNamePage 独立编辑群名页面：替代 AlertDialog 弹窗
- 邀请入群选人页：复用 CreateGroupPage 的选人交互，已有成员预选不可取消
- 群公告页：查看/编辑群公告，群主可发布
- ChatPage 已解散状态适配：输入框禁用 + 提示栏 + 右上角不显示详情按钮
- ChatPage 群公告横幅：群聊有公告时在消息列表顶部显示黄色横幅（喇叭图标 + 单行省略），点击跳转群详情
- ChatPage 监听 GROUP_INFO_UPDATE：实时同步群名/公告/解散状态
- GroupRepository 扩展：新增 addMembers / removeMember / leave / transferOwner / disband / updateAnnouncement / updateGroup 方法
- 群头像修改本版不做

## 2. 现状分析

### 已有能力

- `GroupChatInfoPage`：成员网格 + 群名/群号展示 + 群主入群验证开关
- `GroupRepository`：createGroup / searchGroups / joinGroup / handleJoinRequest / getJoinRequests / getGroupDetail / updateGroupSettings
- `CreateGroupPage`：微信风格选人页（字母索引 + 已选横条 + 自动群名），支持 `initialSelectedIds` 预选
- `ChatPage`：已有 `isGroup` / `onGroupInfo` 参数
- `PinyinUtil`：已迁移到 flash_shared，可直接复用

### 缺失

- GroupChatInfoPage 无邀请/踢人/退群/转让/解散/群公告/群名编辑功能
- 无群公告页面
- 无通用选人组件（MemberPickerPage）
- 无独立编辑群名页面（EditGroupNamePage）
- ChatPage 不感知群聊已解散状态
- ChatPage 不监听 GROUP_INFO_UPDATE 实时推送
- GroupRepository 无成员管理和群信息修改方法
- WsClient 无 groupInfoUpdateStream

## 3. 数据模型与接口

### GroupRepository 新增方法

```dart
/// 邀请入群
Future<int> addMembers(String groupId, List<int> memberIds);

/// 踢人
Future<void> removeMember(String groupId, int userId);

/// 退群
Future<void> leaveGroup(String groupId);

/// 转让群主
Future<void> transferOwner(String groupId, int newOwnerId);

/// 解散群聊
Future<void> disbandGroup(String groupId);

/// 更新群公告
Future<void> updateAnnouncement(String groupId, String announcement);

/// 修改群信息（群名/头像）
Future<void> updateGroup(String groupId, {String? name, String? avatar});
```

### 接口对应

| 客户端方法 | 后端接口 |
|-----------|---------|
| addMembers | POST /groups/{id}/members |
| removeMember | DELETE /groups/{id}/members/{uid} |
| leaveGroup | POST /groups/{id}/leave |
| transferOwner | PUT /groups/{id}/transfer |
| disbandGroup | POST /groups/{id}/disband |
| updateAnnouncement | PUT /groups/{id}/announcement |
| updateGroup | PUT /groups/{id} |

## 4. 核心流程

### 群详情页交互流程

群详情页根据当前用户角色（群主/普通成员）动态显示不同的操作入口：

- **所有成员可见**：成员网格（含"+"邀请按钮）、群头像（只展示不可修改）、群聊名称、群号、群公告入口
- **群主额外可见**："-"踢人按钮、群名可编辑（push EditGroupNamePage）、入群验证开关
- **非群主不展示**：入群验证开关、群管理相关入口
- **普通成员底部**：红色"退出群聊"按钮
- **群主底部**：蓝色"转让群主"按钮 + 红色"解散群聊"按钮（独立按钮，不走群管理菜单）

### 已解散群的 ChatPage

ChatPage 通过 `groupDetailFetcher` 异步拉取群详情获取 `status` 和 `announcement` 字段。如果 `status == 1`：
- 输入框区域替换为灰色提示栏"该群聊已解散"
- 右上角不显示群详情按钮
- 历史消息仍可查看和滚动

ChatPage 同时通过 `groupInfoUpdateStream` 实时监听 GROUP_INFO_UPDATE 推送，动态更新：
- 群名（AppBar 标题）
- 群公告（黄色横幅）
- 解散状态（输入框禁用 + 隐藏详情按钮）

## 5. 项目结构与技术决策

### 变更范围

```
client/modules/
├── flash_shared/lib/src/
│   ├── member_picker_page.dart           # 新建：通用选人页面（微信风格）
│   ├── selectable_member.dart            # 新建：可选成员数据模型
│   └── pinyin_util.dart                  # 已有：拼音工具（已迁移到 flash_shared）
├── flash_im_group/lib/src/
│   ├── data/
│   │   └── group_repository.dart         # 扩展：+7 个新方法
│   └── view/
│       ├── group_chat_info_page.dart     # 大幅扩展：完整群详情页
│       ├── edit_group_name_page.dart     # 新建：独立编辑群名页面
│       └── group_announcement_page.dart  # 新建：群公告页
├── flash_im_chat/lib/src/
│   └── view/
│       └── chat_page.dart                # 扩展：已解散状态 + 群公告横幅 + groupInfoUpdateStream 监听
├── flash_im_core/lib/src/
│   ├── logic/
│   │   └── ws_client.dart                # 扩展：新增 groupInfoUpdateStream
│   └── data/proto/
│       ├── message.pb.dart               # 扩展：GroupInfoUpdate 消息
│       └── ws.pbenum.dart                # 扩展：GROUP_INFO_UPDATE 枚举
├── flash_im_conversation/lib/src/
│   └── logic/
│       └── conversation_list_cubit.dart  # 扩展：监听 groupInfoUpdateStream 更新会话列表 name/avatar

client/lib/src/
└── home/view/home_page.dart              # 扩展：传入 groupDetailFetcher + 退群/解散导航
```

### 技术决策

| 决策 | 方案 | 理由 |
|------|------|------|
| 邀请入群复用 CreateGroupPage | 传入 initialSelectedIds = 已有成员 ID 集合 | 选人交互完全一样，不需要新建页面 |
| 踢人改用 MemberPickerPage | 移除模式（isRemoveMode=true），红色勾选 + 红色按钮 | 比 BottomSheet 更好的交互体验，支持多选和搜索 |
| 退群/解散用确认对话框 | AlertDialog 二次确认 | 不可逆操作需要确认 |
| 群名编辑改为独立页面 | push EditGroupNamePage，返回新群名 | 比 AlertDialog 更好的编辑体验，支持头像展示和字数限制 |
| 邀请入群选人页 | 顶部横条只展示新选的人，已有成员列表中灰色勾选不可点击，完成数字只计新选人数 | 区分已有成员和新选成员，避免误操作 |
| 群公告独立页面 | push GroupAnnouncementPage | 公告内容可能很长，需要全屏展示和编辑 |
| ChatPage 群详情获取 | 通过 groupDetailFetcher 异步拉取（公告 + 解散状态） | ChatPage 不直接依赖 GroupRepository，通过回调解耦 |
| ChatPage 实时同步 | 通过 groupInfoUpdateStream 监听 GROUP_INFO_UPDATE 帧 | 群名/公告/解散状态变更时实时更新，无需手动刷新 |
| GROUP_INFO_UPDATE 驱动更新 | 独立帧驱动会话列表 name/avatar 更新 + ChatPage 标题/公告/解散状态更新 | 不污染 ConversationUpdate，语义清晰 |
| 群头像行只展示不可修改 | 群头像行无 onTap，箭头隐藏但保持占位 | 本版不做群头像修改 |
| 非群主不展示入群验证和群管理 | 根据 _isOwner 条件渲染 | 简化非群主视图，减少无权操作的困惑 |
| 无 onTap 的设置项箭头隐藏 | 箭头颜色设为 transparent，保持占位不影响布局 | 视觉上隐藏箭头，但不改变行高和对齐 |

### 第三方依赖

无需新增第三方依赖。

## 6. 验收标准

| 验收条件 | 验收方式 |
|----------|----------|
| 编译通过 | `flutter analyze` 无错误 |
| 邀请入群：群详情页"+"按钮 → 选人页（已有成员预选）→ 邀请成功 | 手动操作 |
| 踢人：群主点"-" → MemberPickerPage 移除模式 → 选择成员 → 移除成功 | 手动操作 |
| 退群：普通成员点"退出群聊" → 确认 → 返回会话列表 | 手动操作 |
| 转让：群主点"转让群主" → 选择新群主 → 确认 | 手动操作 |
| 解散：群主点"解散群聊" → 二次确认 → 返回会话列表 | 手动操作 |
| 群公告：群主发布/编辑公告，普通成员只能查看 | 手动操作 |
| 群名编辑：群主点击群名 → EditGroupNamePage → 修改成功 | 手动操作 |
| 已解散群：进入后输入框禁用 + 提示栏 + 无详情按钮 | 手动操作 |
| 群公告横幅：群聊有公告时 ChatPage 顶部显示黄色横幅，点击跳转群详情 | 手动操作 |
| WS 实时同步：修改群名后其他成员的会话列表和 ChatPage 标题实时更新 | 手动操作（双设备） |
| WS 实时同步：修改群公告后其他成员的 ChatPage 横幅实时更新 | 手动操作（双设备） |

## 7. 暂不实现

| 功能 | 理由 |
|------|------|
| 全员禁言 UI | 后端 group_info 已预留字段，前端下一版加 |
| 群头像修改 | 本版不做，群头像行只展示不可修改 |
| 退群/解散后 WS 通知 | 通过 GROUP_INFO_UPDATE 实现群信息变更实时推送，解散状态通过 groupDetailFetcher 异步拉取 |
