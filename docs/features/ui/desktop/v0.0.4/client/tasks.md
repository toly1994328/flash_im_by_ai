# 桌面端交互优化 v0.0.4 — 前端任务清单

基于 client/design.md 设计，列出需要修改/新建的具体细节。
全局约束：
- 浮层统一使用 `TolyPopover`（`package:tolyui_feedback/tolyui_feedback.dart`），`isBubble: false` 去掉箭头
- 移动端交互不改动，通过 `kApp.isDesktop` / `kApp.isWindows` 平台判断分流
- 表情面板浮层选择后保持打开（连续选择），@ 选择器使用 `adaptivePush` 弹窗

---

## 执行顺序

1. ✅ 任务 1 — 新建桌面端右键菜单组件
2. ✅ 任务 2 — 消息气泡添加右键触发
3. ✅ 任务 3 — 表情面板改为浮层弹出
4. ✅ 任务 4 — @ 选择器改为 adaptivePush 弹窗
5. ✅ 任务 5 — 转发界面桌面端弹窗化
6. ✅ 任务 6 — Windows 窗口按钮贴顶
7. ✅ 任务 7 — 输入栏增加 @ 按钮（群聊）

---

## 任务 1：新建桌面端右键菜单组件 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/desktop_context_menu.dart`（新建）

### 1.1 创建 DesktopContextMenu 组件 `⬜`

白底卡片竖向列表，每项为 icon + 文字横排。参考微信桌面端右键菜单风格。

```dart
import 'package:flutter/material.dart';
import '../data/message.dart';
import 'message_action_menu.dart'; // 复用 MenuAction 枚举

class DesktopContextMenu extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isGroup;
  final bool isPinned;
  final void Function(MenuAction action) onAction;

  const DesktopContextMenu({...});

  @override
  Widget build(BuildContext context) {
    // 1. 复用 MessageActionMenu._getActions 的逻辑获取操作列表
    // 2. 构建 IntrinsicWidth + Column
    // 3. 每项：InkWell > Padding > Row(Icon, SizedBox(width:10), Text)
    // 4. 项间加 Divider(height: 0.5)
    // 5. 整体 padding vertical: 4
  }
}
```

### 1.2 将 _getActions 提取为公共方法 `⬜`

当前 `MessageActionMenu._getActions` 是私有静态方法，需要改为包级可见，让 `DesktopContextMenu` 也能调用。

文件：`client/modules/flash_im_chat/lib/src/view/message_action_menu.dart`

- 将 `static List<MenuAction> _getActions(...)` 改为 `static List<MenuAction> getActions(...)`（去掉下划线）

---

## 任务 2：消息气泡添加右键触发 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/bubble/message_bubble.dart`（修改）

### 2.1 添加 tolyui_feedback import `⬜`

```dart
import 'package:tolyui_feedback/tolyui_feedback.dart';
import '../desktop_context_menu.dart';
```

### 2.2 桌面端分支包裹 TolyPopover `⬜`

在 `_buildContent` 方法中，气泡的 `GestureDetector` 部分需要按平台分流：

```dart
// 桌面端（判断 kApp.isDesktop）
// 不传 controller，使用 builder 中的 ctrl 操作
Flexible(child: Builder(
  builder: (bubbleCtx) {
    return TolyPopover(
      placement: isMe ? Placement.bottomEnd : Placement.bottomStart,
      maxWidth: 180,
      decorationConfig: DecorationConfig(
        backgroundColor: Colors.white,
        radius: Radius.circular(8),
      ),
      overlayBuilder: (context, ctrl) => DesktopContextMenu(
        message: message,
        isMe: isMe,
        isGroup: isGroup,
        isPinned: isPinned,
        onAction: (action) {
          ctrl.close();
          onAction?.call(action);
        },
      ),
      builder: (context, ctrl, child) => GestureDetector(
        onSecondaryTapUp: (details) => ctrl.open(position: details.localPosition),
        child: child,
      ),
      child: _buildBubble(),
    );
  },
))

// 移动端保持现有 GestureDetector + onLongPressStart 不变
```

### 2.3 添加 onAction 回调参数 `⬜`

`MessageBubble` 需要新增一个 `onAction` 回调，桌面端右键菜单直接调用它而不走 `onLongPress`：

```dart
final void Function(MenuAction action)? onAction;
```

在 `chat_page.dart` 中构建 `MessageBubble` 时传入 `onAction` 处理逻辑（复用现有的 `_handleAction` 方法）。

---

## 任务 3：表情面板改为浮层弹出 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/chat_input_desktop.dart`（修改）

### 3.1 添加 tolyui_feedback import `⬜`

```dart
import 'package:tolyui_feedback/tolyui_feedback.dart';
```

### 3.2 移除 _showEmoji 状态和底部内嵌面板 `⬜`

- 删除 `bool _showEmoji = false;` 状态变量
- 删除 Column 底部的 `if (_showEmoji) SizedBox(height: 200, child: EmojiPanel(...))`

### 3.3 工具栏表情图标包裹 TolyPopover `⬜`

在工具栏 `_buildToolIcon(Icons.emoji_emotions_outlined, ...)` 处替换为：

```dart
TolyPopover(
  placement: Placement.topStart,
  maxWidth: 400,
  maxHeight: 280,
  decorationConfig: DecorationConfig(
    backgroundColor: Colors.white,
    radius: Radius.circular(12),
  ),
  overlay: EmojiPanel(onEmojiSelected: _onEmojiSelected),
  builder: (context, ctrl, child) => GestureDetector(
    onTap: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
    child: child,
  ),
  child: Icon(Icons.emoji_emotions_outlined, size: 22, color: const Color(0xFF666666)),
)
```

---

## 任务 4：@ 选择器改为浮窗 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/chat_input_desktop.dart`（修改）

### 4.1 添加 PopoverController 用于 @ 浮窗 `⬜`

```dart
final PopoverController _mentionCtrl = PopoverController();
```

### 4.2 输入区域包裹 TolyPopover `⬜`

将 TextField 区域（`Container(constraints: ...)` 包含输入框的部分）包裹 `TolyPopover`：

```dart
TolyPopover(
  controller: _mentionCtrl,
  placement: Placement.topStart,
  maxHeight: 240,
  maxWidth: 280,
  decorationConfig: DecorationConfig(
    backgroundColor: Colors.white,
    radius: Radius.circular(8),
  ),
  overlay: MentionPicker(
    fetcher: widget.membersFetcher,
    members: widget.groupMembers,
    showAll: true,
    onSelect: (userId, nickname) {
      _onMentionSelected(userId, nickname);
      _mentionCtrl.close();
    },
    onDismiss: _mentionCtrl.close,
  ),
  child: _buildInputArea(), // 原有的 TextField Container
)
```

### 4.3 修改 _openMentionPicker 方法 `⬜`

替换整个方法体：

```dart
void _openMentionPicker() {
  if (!widget.isGroup) return;
  _mentionCtrl.open();
}
```

移除原有的 `Navigator.push(MaterialPageRoute(...))` 全屏跳转逻辑。

### 4.4 在 _onTextChanged 中关闭浮窗条件 `⬜`

当用户删除 @ 字符或清空输入时，主动关闭浮窗：

```dart
// 在 _onTextChanged 中补充：
if (_mentionCtrl.isOpen) {
  final String text = _controller.text;
  final int offset = _controller.selection.baseOffset;
  // 如果光标前不再有 @ 字符，关闭浮窗
  if (offset <= 0 || !text.substring(0, offset).contains('@')) {
    _mentionCtrl.close();
  }
}
```

---

## 任务 5：编译验证 `⬜ 待处理`

### 5.1 flutter analyze `⬜`

```bash
cd client
flutter analyze
```

确认零错误零警告。

### 5.2 Windows 桌面端运行验证 `⬜`

```bash
cd client
flutter run -d windows --dart-define-from-file=.env.dev
```

验证清单：
- [ ] 表情图标点击弹出浮层，选择后插入输入框
- [ ] 表情浮层点击外部自动关闭
- [ ] 群聊中输入 @ 弹出成员小浮窗
- [ ] 选择成员后补全并关闭浮窗
- [ ] 右键消息气泡弹出操作菜单
- [ ] 菜单操作可正常执行（复制/引用/撤回/删除）
- [ ] 移动端（Android）长按和底部面板行为不变
