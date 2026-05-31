# ui/desktop — 前端任务清单

基于实际实现，记录所有已完成的任务。

---

## 执行顺序

1. ✅ 任务 1 — DesktopSettingsPanel 设置三栏面板
2. ✅ 任务 2 — ChatPage onToggleDetail + 聊天详情侧栏浮层
3. ✅ 任务 3 — 通讯录右侧面板切换
4. ✅ 任务 4 — 弹窗化操作（搜索/创建群/加好友）
5. ✅ 任务 5 — 好友详情桌面端适配（embedded 模式）
6. ✅ 任务 6 — 底部菜单（TolyDropMenu）
7. ✅ 任务 7 — 文件拆分（desktop/ 子目录）
8. ✅ 任务 8 — 通用组件封装（adaptivePush + UnreadBadge + context.rx）
9. ✅ 任务 9 — 意见反馈功能
10. ✅ 任务 10 — Bug 修复

---

## 任务 1：DesktopSettingsPanel `✅`

文件：`client/lib/src/home/profile/desktop_settings_panel.dart`（新建）

- 左侧菜单列表（220px）：个人资料/修改密码/关于闪讯/用户协议/隐私政策
- 右侧内容区：独立 Navigator 包裹，Theme 覆盖隐藏子页面 AppBar
- 顶部标题栏：动态标题 + WindowsButtons
- 底部退出登录按钮
- 用户协议/隐私政策 → launchUrl 打开浏览器

---

## 任务 2：聊天详情侧栏 `✅`

文件：
- `flash_im_chat/chat_page.dart`（修改）：新增 `onToggleDetail` 参数
- `flash_im_chat/private_chat_info_page.dart`（修改）：新增 `showAppBar` 参数
- `flash_im_group/group_chat_info_page.dart`（修改）：新增 `showAppBar` 参数
- `desktop/desktop_layout.dart`：AnimationController + SlideTransition + TapRegion

实现细节：
- 浮层 Stack + Positioned（top: kToolbarHeight+0.5, right: 0, width: 320）
- SlideTransition Offset(1,0)→Offset.zero，200ms easeOutCubic
- TapRegion onTapOutside 关闭
- 独立 Navigator 包裹侧栏内容
- 切换会话时自动 reverse 收起

---

## 任务 3：通讯录右侧面板 `✅`

文件：
- `desktop/contact_detail_panel.dart`（新建）
- `flash_im_friend/friend_list_page.dart`（修改）：新增 `showAppBar`
- `flash_im_friend/friend_request_page.dart`（修改）：新增 `showAppBar`
- `flash_im_group/my_groups_page.dart`（修改）：新增 `showAppBar`
- `flash_im_group/group_notifications_page.dart`（修改）：新增 `showAppBar`

实现细节：
- `_contactPanelType` 状态：null/requests/groups/notifications
- 顶部标题栏：动态标题 + WindowsButtons
- 通讯录面板顶部 24px DragMoveArea 色块

---

## 任务 4：弹窗化操作 `✅`

文件：`desktop/actions_mixin.dart`（新建）

方法：
- `showCreateGroupDialog`：420×80% 弹窗，CreateGroupPage
- `showAddFriendDialog`：420×80% 弹窗，独立 Navigator + UserSearchPage
- `showSearchDialog`：480×80% 弹窗，独立 Navigator + SearchPage（embedded + onClose）
- `showSettingsDialogAction`：420×80% 弹窗，独立 Navigator + SettingsPage
- `showFeedbackDialog`：420×60% 弹窗，FeedbackPage + Provider 注入

---

## 任务 5：好友详情桌面端适配 `✅`

文件：`flash_im_friend/friend_detail_page.dart`（修改）

- 新增 `embedded` 参数
- 桌面端布局：白色背景 + maxWidth 480 + 居中
- 分组展示：头像区 → 朋友资料 → 更多信息 → 操作按钮
- 操作按钮：圆形图标横排（发消息蓝色 + 删除好友红色）

---

## 任务 6：底部菜单 `✅`

文件：`desktop/nav_rail.dart`

- TolyDropMenu + Placement.rightEnd + DecorationConfig(isBubble: false)
- 菜单项：系统设置/意见反馈/退出登录
- childBuilder + GestureDetector 触发 ctrl.open()
- 未读角标：BlocBuilder 监听 totalUnread

---

## 任务 7：文件拆分 `✅`

从 `desktop_layout.dart`（806行）拆为：

| 文件 | 行数 | 职责 |
|------|------|------|
| desktop_layout.dart | ~250 | 主框架 + 状态管理 |
| nav_rail.dart | ~100 | 侧边导航栏组件 |
| conversation_panel.dart | ~80 | 消息 Tab 会话面板 |
| chat_detail_sidebar.dart | ~70 | 聊天详情侧栏 |
| contact_detail_panel.dart | ~70 | 通讯录右侧面板 |
| actions_mixin.dart | ~200 | 弹窗操作 mixin |

---

## 任务 8：通用组件封装 `✅`

### adaptivePush

文件：`flash_shared/lib/src/adaptive_push.dart`

- 根据 `context.rx.isDesktop` 判断
- 桌面端：showDialog + 独立 Navigator
- 移动端：Navigator.push

### UnreadBadge

文件：`flash_shared/lib/src/badge.dart`

- BadgeSize 枚举：small(16px) / medium(20px) / large(24px)
- 1-2 位数正圆，3 位数（99+）胶囊形
- 统一替换：nav_rail + mobile_layout + conversation_tile

### context.rx

文件：`tolyui_rx_layout/lib/src/responsive/rx_context.dart`

- `context.rx` → 当前 Rx 断点
- 基于 MediaQuery.sizeOf + ReParserStrategyTheme

---

## 任务 9：意见反馈 `✅`

文件：`client/lib/src/home/profile/feedback_page.dart`（新建）

- 界面：标题 + 提示文字 + 多行输入框 + 提交按钮
- 逻辑：createPrivate(100000000) → ChatCubit.sendMessage
- 桌面端：弹窗 + Provider 注入（ConversationRepository + MessageRepository + WsClient + SessionCubit）
- 发送后：onSent 回调 → 关闭弹窗 → 激活会话

---

## 任务 10：Bug 修复 `✅`

| Bug | 文件 | 修复 |
|-----|------|------|
| tolyui_feedback 溢出算法 rightEnd/leftEnd 被错误回退 | algorithm.dart | 提前 return 条件改为精确匹配 + outBottom 保持原位 |
| ConversationRepository.getList 本地缓存忽略 type 过滤 | conversation_repository.dart | 加 `if (type != null) list.where(...)` |
| UserSearchPage 全局 loading 遮罩 | user_search_page.dart | 改为内联 _isLoading 状态 |
| GroupChatInfoPage Container+ListTile 断言 | group_chat_info_page.dart | Container 改为 Material |
| PrivateChatInfoPage Container+ListTile 断言 | private_chat_info_page.dart | Container 改为 Material |
