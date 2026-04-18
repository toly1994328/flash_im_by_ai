# 群聊（创建与加入） — 客户端任务清单

基于 [design.md](design.md) 设计，列出需要创建/修改的具体细节。

全局约束：
- 状态管理使用 Cubit，不使用 Event 模式
- 群聊头像：GroupAvatarWidget 解析 grid: 前缀渲染九宫格，无 avatar 时显示绿色群图标
- 系统消息：sender_id=999999999 时显示居中灰色标签

---

## 执行顺序

1. ✅ 任务 1 — group_models.dart 新建
2. ✅ 任务 2 — conversation_repository.dart 扩展
3. ✅ 任务 3 — conversation.dart 模型修复
4. ✅ 任务 4 — create_group_page.dart 新建
5. ✅ 任务 5 — private_chat_info_page.dart 新建
6. ✅ 任务 6 — my_groups_page.dart 新建
7. ✅ 任务 7 — conversation_tile.dart 群聊头像适配
8. ✅ 任务 8 — chat_page.dart 右上角按钮
9. ✅ 任务 9 — 模块导出调整
10. ✅ 任务 10 — home_page.dart 组装
11. ✅ 任务 11 — GroupAvatarWidget 九宫格头像组件
12. ✅ 任务 12 — WxPopupMenuButton 弹出菜单
13. ✅ 任务 13 — 系统消息样式
14. ✅ 任务 14 — ConversationListCubit avatar 修复
15. ✅ 任务 15 — SelectableMember letter 字段 + PinyinUtil 导出
16. ✅ 任务 16 — 通讯录入口改造
17. ✅ 任务 17 — 编译验证
18. ⬜ 任务 18 — 拆分 flash_im_group 独立模块

---

## 任务 1：group_models.dart — 群聊数据模型 `✅ 已完成`

文件：`client/modules/flash_im_conversation/lib/src/data/group_models.dart`（新建）

- ✅ `CreateGroupResult`：群名 + 成员 ID 列表，CreateGroupPage 的返回值
- ✅ `SelectableMember`：id + nickname + avatar + letter（拼音首字母），CreateGroupPage 的成员项

---

## 任务 2：conversation_repository.dart — 扩展 `✅ 已完成`

文件：`client/modules/flash_im_conversation/lib/src/data/conversation_repository.dart`（修改）

- ✅ `getList` 新增可选 `type` 参数（`GET /conversations?type=1` 只返回群聊）
- ✅ `createGroup` 方法（`POST /conversations`，body: `{type: "group", name, member_ids}`）

---

## 任务 3：conversation.dart — 群聊显示适配 `✅ 已完成`

文件：`client/modules/flash_im_conversation/lib/src/data/conversation.dart`（修改）

- ✅ `displayAvatar`：群聊时返回 `avatar`（conversations.avatar），单聊时返回 `peerAvatar`
- ✅ `isGroup` getter：`type == 1`

---

## 任务 4：create_group_page.dart — 创建群聊页 `✅ 已完成`

文件：`client/modules/flash_im_conversation/lib/src/view/create_group_page.dart`（新建）

微信风格选人页：
- ✅ 接收 `List<SelectableMember>` + `initialSelectedIds`（预选成员不可取消）
- ✅ 顶部 FlashSearchBar（editable 模式）+ 搜索过滤好友列表
- ✅ 已选头像横条（水平滚动，点击 × 取消选择）放在搜索框下方
- ✅ 好友列表按 `letter` 字母分组，带分组标题（白色背景）
- ✅ 右侧字母索引栏（拖动快速跳转 + 中间大字母指示器）
- ✅ 绿色圆形勾选框（`#07C160`）
- ✅ 标题"选择联系人"，按钮"完成(N)"，`_canCreate` = `_selectedIds.length >= 2`
- ✅ 群名由 `_buildGroupName()` 自动拼接（≤3 人用顿号连接，>3 人取前三 + "等"）
- ✅ 返回 `CreateGroupResult`，不直接调 API

---

## 任务 5：private_chat_info_page.dart — 单聊详情页 `✅ 已完成`

文件：`client/modules/flash_im_chat/lib/src/view/private_chat_info_page.dart`（新建）

- ✅ StatelessWidget，接收 peerName / peerAvatar / peerUserId / onAddMember
- ✅ 顶部成员区域 Wrap 布局：对方头像 + "+"虚线框按钮
- ✅ 点击"+"触发 `onAddMember` 回调

---

## 任务 6：my_groups_page.dart — 我的群聊页 `✅ 已完成`

文件：`client/modules/flash_im_conversation/lib/src/view/my_groups_page.dart`（新建）

- ✅ 加载已加入群聊：`repository.getList(type: 1, limit: 200)`
- ✅ 顶部 FlashSearchBar 本地过滤搜索
- ✅ 群聊列表项：宫格头像（解析 grid:）或默认绿色群图标 + 群名
- ✅ 点击群聊通过 `onGroupTap` 回调跳转 ChatPage
- ✅ 下拉刷新

---

## 任务 7：conversation_tile.dart — 群聊头像适配 `✅ 已完成`

文件：`client/modules/flash_im_conversation/lib/src/view/conversation_tile.dart`（修改）

- ✅ `_buildAvatarImage` 群聊分支：解析 `grid:` 前缀调用 GroupAvatarWidget，无头像时显示绿色群图标

---

## 任务 8：chat_page.dart — 右上角按钮 `✅ 已完成`

文件：`client/modules/flash_im_chat/lib/src/view/chat_page.dart`（修改）

- ✅ 新增参数 `isGroup` / `peerUserId` / `onAddMember`
- ✅ 单聊：右上角"..."→ push PrivateChatInfoPage
- ✅ 群聊：右上角群图标（群详情页下一版本实现）

---

## 任务 9：模块导出调整 `✅ 已完成`

- ✅ `flash_im_conversation.dart` 导出 group_models / create_group_page / my_groups_page
- ✅ `flash_im_chat.dart` 导出 private_chat_info_page
- ✅ `flash_im_friend.dart` 导出 pinyin_helper.dart

---

## 任务 10：home_page.dart — 入口组装 `✅ 已完成`

文件：`client/lib/src/home/view/home_page.dart`（修改）

- ✅ 消息 Tab 右上角改为 WxPopupMenuButton（发起群聊 / 添加朋友 / 扫一扫）
- ✅ `_openCreateGroup`：Friend → SelectableMember（含 PinyinUtil.getFirstLetter）→ push CreateGroupPage → createGroup → push ChatPage
- ✅ `_createGroupFromChat`：从单聊发起，预选对方
- ✅ 通讯录 Tab "群聊"入口 → push MyGroupsPage
- ✅ ChatPage 调用传入 isGroup / peerUserId / onAddMember

---

## 任务 11：GroupAvatarWidget 九宫格头像组件 `✅ 已完成`

- ✅ `flash_shared/lib/src/group_avatar_widget.dart` 新建
- ✅ GroupAvatarMember（id + avatarUrl）+ GroupAvatarWidget（1~9人宫格布局）
- ✅ 内部用 AvatarWidget 渲染每个格子（支持 identicon:）
- ✅ flash_shared.dart 导出

---

## 任务 12：WxPopupMenuButton 弹出菜单 `✅ 已完成`

- ✅ `flash_shared/lib/src/popup_menu_button.dart` 新建
- ✅ WxMenuItem（icon + text + onTap）+ WxPopupMenuButton（Overlay + 尖角气泡 + 缩放动画）
- ✅ flash_shared.dart 导出

---

## 任务 13：系统消息样式 `✅ 已完成`

- ✅ `message.dart` 新增 `bool get isSystem => senderId == '999999999'`
- ✅ `message_bubble.dart` build 方法开头判断 isSystem，渲染居中灰色圆角标签

---

## 任务 14：ConversationListCubit avatar 修复 `✅ 已完成`

- ✅ `conversation_list_cubit.dart` _handleUpdate 中更新已有会话时补充 `avatar: c.avatar`
- ✅ 修复群聊收到新消息后宫格头像丢失的问题

---

## 任务 15：SelectableMember letter 字段 + PinyinUtil 导出 `✅ 已完成`

- ✅ `group_models.dart` SelectableMember 新增 `letter` 字段（String，默认 '#'）
- ✅ `flash_im_friend/flash_im_friend.dart` 新增导出 `src/utils/pinyin_helper.dart`
- ✅ `home_page.dart` _friendsToMembers 中用 `PinyinUtil.getFirstLetter` 计算 letter 传入

---

## 任务 16：通讯录入口改造 `✅ 已完成`

- ✅ `friend_list_page.dart` 通讯录入口：新的朋友 + 群聊（Icons.group，绿色）
- ✅ `home_page.dart` 群聊入口跳转 MyGroupsPage，点击群聊组装 ChatCubit + ChatPage

---

## 任务 17：编译验证 `✅ 已完成`

- ✅ `flutter analyze` 无错误
- ✅ 手动测试路径：
  1. 消息 Tab "+" → 发起群聊 → 选好友 → 完成 → 进入群聊 ChatPage
  2. 单聊 ChatPage → "..." → 单聊详情页 → "+" → 创建群聊页（对方预选中）→ 创建
  3. 会话列表 → 群聊显示群名称 + 宫格头像
  4. 通讯录 → 群聊 → 我的群聊列表 → 点击进入群聊
  5. 群聊中发消息 → 其他成员收到并显示发送者昵称

---

## 任务 18：新建 flash_im_group 独立模块 `⬜ 待处理`

群聊相关的页面和模型放在独立的 flash_im_group package 中，和 flash_im_friend 独立的理由一样——职责不同，生长方向不同。

### 18.1 新建 flash_im_group package `⬜`

- `client/modules/flash_im_group/`（pubspec.yaml + lib/flash_im_group.dart）
- 依赖：flash_shared、flutter

### 18.2 数据模型 `⬜`

- `flash_im_group/lib/src/data/group_models.dart`：CreateGroupResult + SelectableMember

### 18.3 页面 `⬜`

- `flash_im_group/lib/src/view/create_group_page.dart`：微信风格选人页
- `flash_im_group/lib/src/view/my_groups_page.dart`：我的群聊列表

### 18.4 GroupRepository `⬜`

- `flash_im_group/lib/src/data/group_repository.dart`：createGroup 方法

### 18.5 导出和依赖 `⬜`

- flash_im_group/lib/flash_im_group.dart 导出所有公开类
- home_page.dart import flash_im_group
- client/pubspec.yaml 新增 flash_im_group 依赖

### 18.6 编译验证 `⬜`

- `flutter analyze` 无错误
