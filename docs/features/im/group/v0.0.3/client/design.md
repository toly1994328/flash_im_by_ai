---
module: im-group
version: v0.0.3
date: 2026-04-21
tags: [群聊, 成员管理, 踢人, 退群, 转让, 解散, 群公告, 群设置, Flutter]
---

# 群成员管理与群详情 — 客户端设计报告

> 关联设计：[服务端设计](../server/design.md) | [功能分析](../analysis.md) | [v0.0.2 客户端](../../v0.0.2/client/design.md)

## 1. 目标

- GroupChatInfoPage 大幅扩展：从最小版本（成员网格 + 入群验证开关）到完整版本（邀请/踢人/退群/转让/解散/群公告/群名编辑/群管理菜单）
- 邀请入群选人页：复用 CreateGroupPage 的选人交互，已有成员预选不可取消
- 群公告页：查看/编辑群公告，群主可发布
- ChatPage 已解散状态适配：输入框禁用 + 提示栏 + 右上角不显示详情按钮
- ChatPage 群公告横幅：群聊有公告时在消息列表顶部显示黄色横幅（喇叭图标 + 单行省略），点击跳转群详情
- GroupRepository 扩展：新增 addMembers / removeMember / leave / transferOwner / disband / updateAnnouncement / updateGroup 方法

## 2. 现状分析

### 已有能力

- `GroupChatInfoPage`：成员网格 + 群名/群号展示 + 群主入群验证开关
- `GroupRepository`：createGroup / searchGroups / joinGroup / handleJoinRequest / getJoinRequests / getGroupDetail / updateGroupSettings
- `CreateGroupPage`：微信风格选人页（字母索引 + 已选横条 + 自动群名），支持 `initialSelectedIds` 预选
- `ChatPage`：已有 `isGroup` / `onGroupInfo` 参数

### 缺失

- GroupChatInfoPage 无邀请/踢人/退群/转让/解散/群公告/群名编辑功能
- 无群公告页面
- ChatPage 不感知群聊已解散状态
- GroupRepository 无成员管理和群信息修改方法

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

- **所有成员可见**：成员网格（含"+"邀请按钮）、群聊名称、群号、群公告入口
- **群主额外可见**："-"踢人按钮、群管理入口（转让/解散）、入群验证开关、群名可编辑
- **普通成员底部**：红色"退出群聊"按钮
- **群主底部**：红色"解散群聊"按钮

### 已解散群的 ChatPage

ChatPage 通过 `GET /groups/{id}/detail` 获取 `status` 字段。如果 `status == 1`：
- 输入框区域替换为灰色提示栏"该群聊已解散"
- 右上角不显示群详情按钮
- 历史消息仍可查看和滚动

## 5. 项目结构与技术决策

### 变更范围

```
client/modules/
├── flash_im_group/lib/src/
│   ├── data/
│   │   └── group_repository.dart         # 扩展：+7 个新方法
│   └── view/
│       ├── group_chat_info_page.dart     # 大幅扩展：完整群详情页
│       └── group_announcement_page.dart  # 新建：群公告页
├── flash_im_chat/lib/src/
│   └── view/
│       └── chat_page.dart                # 扩展：已解散状态适配

client/lib/src/
└── home/view/home_page.dart              # 扩展：邀请入群回调 + 退群/解散后导航
```

### 技术决策

| 决策 | 方案 | 理由 |
|------|------|------|
| 邀请入群复用 CreateGroupPage | 传入 initialSelectedIds = 已有成员 ID 集合 | 选人交互完全一样，不需要新建页面 |
| 踢人用 BottomSheet 选择 | 弹出成员列表（排除群主），点击确认移除 | 比进入新页面更轻量 |
| 退群/解散用确认对话框 | AlertDialog 二次确认 | 不可逆操作需要确认 |
| 群名编辑用 AlertDialog | 弹出 TextField 对话框 | 和好友备注编辑一致的交互模式 |
| 群公告独立页面 | push GroupAnnouncementPage | 公告内容可能很长，需要全屏展示和编辑 |
| 已解散状态在 ChatPage 检测 | 通过 onGroupInfo 回调获取 status，或新增 isDisband 参数 | ChatPage 不直接依赖 GroupRepository |

### 第三方依赖

无需新增第三方依赖。

## 6. 验收标准

| 验收条件 | 验收方式 |
|----------|----------|
| 编译通过 | `flutter analyze` 无错误 |
| 邀请入群：群详情页"+"按钮 → 选人页（已有成员预选）→ 邀请成功 | 手动操作 |
| 踢人：群主点"-" → 选择成员 → 确认 → 成员被移除 | 手动操作 |
| 退群：普通成员点"退出群聊" → 确认 → 返回会话列表 | 手动操作 |
| 转让：群主点"群管理" → "转让群主" → 选择新群主 → 确认 | 手动操作 |
| 解散：群主点"群管理" → "解散群聊" → 二次确认 → 返回会话列表 | 手动操作 |
| 群公告：群主发布/编辑公告，普通成员只能查看 | 手动操作 |
| 群名编辑：群主点击群名 → 弹出编辑框 → 修改成功 | 手动操作 |
| 群头像修改：群主点击群头像 → 选择图片 → 上传 → 更新成功 | 手动操作 |
| 已解散群：进入后输入框禁用 + 提示栏 + 无详情按钮 | 手动操作 |
| 群公告横幅：群聊有公告时 ChatPage 顶部显示黄色横幅，点击跳转群详情 | 手动操作 |

## 7. 暂不实现

| 功能 | 理由 |
|------|------|
| 全员禁言 UI | 后端 group_info 已预留字段，前端下一版加 |
| 退群/解散后 WS 通知其他成员刷新 | 本版本靠系统消息通知，不做实时 UI 刷新 |
