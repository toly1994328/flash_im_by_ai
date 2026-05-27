# 桌面端 UI 适配 — 前端任务清单

基于 design.md 设计，按"公共块 + 组装"原则拆分实现。

---

## 执行顺序

1. ✅ 任务 1 — 添加依赖（tolyui_rx_layout, window_manager, fx_env）
2. ✅ 任务 2 — HomePage 拆分（home_actions_mixin + mobile_layout + desktop_layout）
3. ✅ 任务 3 — 桌面端布局（DesktopLayout：侧边栏 + 三栏/两栏切换）
4. ✅ 任务 4 — ChatPage embedded 模式
5. ✅ 任务 5 — 桌面端输入框（ChatInputDesktop）
6. ✅ 任务 6 — 窗口管理（window_manager 初始化）
7. ✅ 任务 7 — 会话选中高亮（activeConversationId + isActive）
8. ✅ 任务 8 — 弹出菜单桌面端适配（白色卡片 + 居中定位）
9. ✅ 任务 9 — IM 调色主题（FlashImTheme ThemeExtension）
10. ⬜ 任务 10 — 编译验证 + 测试

---

## 任务 1：添加依赖 `✅ 已完成`

文件：`client/pubspec.yaml` + 子模块 pubspec

- `tolyui_rx_layout: 1.0.0+2` — 响应式布局
- `window_manager: ^0.4.3` — 窗口管理
- `fx_env: 0.0.1+3` — 平台检测

---

## 任务 2：HomePage 拆分 `✅ 已完成`

### 2.1 home_actions_mixin.dart（新建）

公共动作 mixin，包含：
- `openChat` — 全屏 push 聊天页（移动端用）
- `buildChatPanel` — 嵌入式聊天面板（桌面端用，传 `embedded: true`）
- `openSearch` / `openFriendDetail` / `openCreateGroup` / `openAddFriend`
- `friendsToMembers` — 好友列表转成员列表

### 2.2 mobile_layout.dart（新建）

移动端布局组装：底部导航 + IndexedStack + 全屏跳转。
通过 `homeState` 访问公共方法。

### 2.3 home_page.dart（重写）

精简为入口：initState + `Rx$` 分发。
`HomePageState` 公开 `convCubit` / `groupNotifCubit`。

### 2.4 desktop_layout.dart（新建）

桌面端布局组装：侧边栏 + 内容区。

---

## 任务 3：桌面端布局 `✅ 已完成`

文件：`client/lib/src/home/view/desktop_layout.dart`

- 自定义侧边导航栏（72px）：头像 + 消息/通讯录/我 + 底部设置
- 消息 Tab（index 0）：三栏 Row（会话列表 320px + 聊天区 Expanded）
- 通讯录 Tab（index 1）：FriendListPage 占满
- 我 Tab（index 2）：ProfilePage 占满
- 设置（index 3）：SettingsPage 占满
- 侧边栏支持 DragToMoveArea 拖拽
- 搜索栏区域支持 DragToMoveArea 拖拽

---

## 任务 4：ChatPage embedded 模式 `✅ 已完成`

文件：`client/modules/flash_im_chat/lib/src/view/chat_page.dart`

新增 `embedded` 参数（默认 false）：
- `embedded: true` → 白色 AppBar、标题 14px 居左、无返回按钮、DragToMoveArea、底部分割线、使用 ChatInputDesktop
- `embedded: false` → 移动端样式不变

---

## 任务 5：桌面端输入框 `✅ 已完成`

文件：`client/modules/flash_im_chat/lib/src/view/chat_input_desktop.dart`（新建）

微信桌面端风格：
- 外层圆角边线框包裹整体（输入区 + 工具栏）
- 白色背景 + 浅灰边线 + 柔和阴影
- 输入区：多行 TextField，minLines 3
- 工具栏在下方：表情/图片/文件图标
- Enter 发送，Shift+Enter 换行
- 无发送按钮（纯键盘操作）

---

## 任务 6：窗口管理 `✅ 已完成`

文件：`client/lib/main.dart`

```dart
if (kApp.isDesktop) {
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(400, 600),
    center: true,
    titleBarStyle: TitleBarStyle.hidden,
    title: '闪讯',
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
```

---

## 任务 7：会话选中高亮 `✅ 已完成`

文件：
- `conversation_list_page.dart` — 新增 `activeConversationId` 参数
- `conversation_tile.dart` — 新增 `isActive` 参数，高亮色 `#E8F0FE`

移动端不传 activeConversationId（默认 null），不受影响。

---

## 任务 8：弹出菜单桌面端适配 `✅ 已完成`

文件：`client/modules/flash_shared/lib/src/popup_menu_button.dart`

- 桌面端：白色卡片 + 白色尖角 + 阴影 + 深色文字，严格居中在按钮下方，仅淡入动画
- 移动端：深色气泡 + 深色尖角 + 白色文字（不变）
- 定位基于按钮实际屏幕坐标计算

---

## 任务 9：IM 调色主题 `✅ 已完成`

文件：
- `client/modules/flash_shared/lib/src/theme/flash_im_theme.dart`（新建）
- `client/lib/src/application/app.dart`（注册 ThemeExtension）
- `client/lib/src/home/view/desktop_layout.dart`（使用 `context.imTheme`）

`FlashImTheme` 通过 ThemeExtension 注入，统一管理：
- `primary` — 主色
- `sidebarColor` — 侧边栏背景
- `headerColor` — 搜索栏/标题栏背景
- `activeConversationColor` — 会话激活高亮
- `navActiveColor` — 导航图标选中背景
- `dividerColor` / `scaffoldColor` / `inputBackgroundColor`

便捷访问：`context.imTheme.sidebarColor`

---

## 任务 10：编译验证 + 测试 `⬜ 待处理`

### 9.1 静态分析

```bash
cd client && flutter analyze
```

### 9.2 macOS 构建

```bash
cd client && flutter build macos --release --dart-define-from-file=.env.production
```

### 9.3 手动验证

| 场景 | 预期结果 |
|------|---------|
| macOS 窗口 >= 断点值 | 桌面端布局 |
| macOS 缩小窗口 | 回退移动端布局 |
| 消息 Tab | 三栏：侧边栏 + 会话列表 + 聊天区 |
| 通讯录 Tab | 两栏：侧边栏 + 通讯录占满 |
| 设置按钮 | 两栏：侧边栏 + 设置页占满 |
| 点击会话 | 右侧显示聊天，列表项高亮 |
| 侧边栏拖拽 | 可拖动窗口 |
| 桌面端输入框 | 白色圆角框 + Enter 发送 |
| 弹出菜单 | 白色卡片居中在按钮下方 |
| Android 运行 | 移动端布局不变 |
