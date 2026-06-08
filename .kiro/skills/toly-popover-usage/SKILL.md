---
name: toly-popover-usage
description: TolyPopover 浮层组件使用规范。在需要实现弹出浮层（表情面板、右键菜单、@选择器等）时激活，确保使用正确的 API 和配置方式。
metadata:
  model: manual
  last_modified: Mon, 08 Jun 2026 00:00:00 GMT

---

# TolyPopover 浮层组件使用指南

## 适用场景

当需要在某个触发元素附近弹出浮层内容时使用，例如：
- 表情面板（点击图标弹出）
- 右键上下文菜单（右键弹出）
- @ 成员选择器（输入触发弹出）
- 下拉菜单、工具提示

## 来源

包名：`tolyui_feedback`（通过 `package:tolyui_feedback/tolyui_feedback.dart` 导入）

## 核心 API

### TolyPopover

包裹触发元素的 Widget，内部管理浮层的显隐和定位。

```dart
TolyPopover(
  // 浮层方位（相对于触发元素）
  placement: Placement.top,
  
  // 浮层内容（静态）
  overlay: EmojiPanel(onEmojiSelected: _onSelect),
  
  // 或：浮层内容（动态，可获取 controller）
  overlayBuilder: (context, ctrl) => MyContent(onClose: ctrl.close),
  
  // 控制器（可选，不传则内部自动创建）
  controller: _popCtrl,
  
  // 触发元素构建器（可获取 controller 来手动控制开关）
  builder: (context, ctrl, child) => GestureDetector(
    onTap: ctrl.open,
    child: child,
  ),
  
  // 子组件（builder 中的 child 参数）
  child: Icon(Icons.emoji_emotions_outlined),
  
  // 点击外部是否关闭（默认 true）
  barrierDismissible: true,
  
  // 浮层最大宽高
  maxWidth: 360,
  maxHeight: 300,
  
  // 装饰配置（气泡尖角 or 普通卡片）
  decorationConfig: DecorationConfig(
    backgroundColor: Colors.white,
    radius: Radius.circular(12),
  ),
  
  // 生命周期回调
  onOpen: () => debugPrint('opened'),
  onClose: () => debugPrint('closed'),
)
```

### PopoverController

手动控制浮层开关：

```dart
final PopoverController _ctrl = PopoverController();

// 打开浮层
_ctrl.open();

// 关闭浮层
_ctrl.close();

// 查询状态
_ctrl.isOpen;

// 通过右键位置打开（用于右键菜单）
_ctrl.open(position: details.localPosition);
```

### Placement 枚举

浮层相对于触发元素的方位：

| 值 | 说明 |
|----|------|
| `Placement.top` | 上方居中 |
| `Placement.topStart` | 上方左对齐 |
| `Placement.topEnd` | 上方右对齐 |
| `Placement.bottom` | 下方居中 |
| `Placement.bottomStart` | 下方左对齐 |
| `Placement.bottomEnd` | 下方右对齐 |
| `Placement.left` | 左侧居中 |
| `Placement.right` | 右侧居中 |

### DecorationConfig

浮层外观装饰：

```dart
// 普通卡片（圆角 + 阴影，无箭头）
DecorationConfig(
  backgroundColor: Colors.white,
  radius: Radius.circular(12),
  isBubble: false, // 默认 true，不设会带气泡尖角！
)

// 带气泡尖角（默认行为）
DecorationConfig(
  backgroundColor: Colors.white,
  radius: Radius.circular(8),
  // isBubble: true（默认）
  bubbleMeta: BubbleMeta(spineHeight: 8, angle: 70),
)
```

## 使用模式

### 模式一：点击触发（表情面板）

```dart
TolyPopover(
  placement: Placement.topStart,
  maxWidth: 400,
  maxHeight: 280,
  overlay: EmojiPanel(onEmojiSelected: _onEmojiSelected),
  builder: (context, ctrl, child) => GestureDetector(
    onTap: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
    child: child,
  ),
  child: const Icon(Icons.emoji_emotions_outlined, size: 22),
)
```

### 模式二：右键触发（上下文菜单）

```dart
final PopoverController _menuCtrl = PopoverController();

TolyPopover(
  controller: _menuCtrl,
  placement: Placement.bottomStart,
  overlayBuilder: (context, ctrl) => _buildContextMenu(ctrl),
  builder: (context, ctrl, child) => GestureDetector(
    onSecondaryTapUp: (details) {
      ctrl.open(position: details.localPosition);
    },
    child: child,
  ),
  child: MessageBubbleContent(...),
)
```

### 模式三：输入触发（@ 选择器）

```dart
final PopoverController _mentionCtrl = PopoverController();

TolyPopover(
  controller: _mentionCtrl,
  placement: Placement.topStart,
  maxHeight: 200,
  overlay: MentionPicker(
    members: _members,
    onSelect: (userId, nickname) {
      _onMentionSelected(userId, nickname);
      _mentionCtrl.close();
    },
    onDismiss: _mentionCtrl.close,
  ),
  child: TextField(
    controller: _textController,
    onChanged: (text) {
      if (_shouldShowMention(text)) {
        _mentionCtrl.open();
      }
    },
  ),
)
```

## 注意事项

1. **不要用 OverlayEntry**：TolyPopover 内部基于 `OverlayPortal`（Flutter 3.x 原生），自动管理浮层生命周期，不需要手动管理 OverlayEntry。

2. **barrierDismissible**：默认 true，点击外部自动关闭。如果浮层内有输入框（如搜索），注意 `TapRegion` 的分组不要冲突。

3. **滚动自动关闭**：TolyPopover 内置了 `PopHideMixin`，当页面滚动时会自动关闭浮层。

4. **动画**：内置淡入淡出动画（默认 250ms），通过 `animDuration` 和 `reverseDuration` 可调。

5. **position 参数**：`ctrl.open(position: offset)` 传入的是相对于触发元素的局部坐标，用于右键菜单场景定位。

6. **maxWidth/maxHeight**：约束浮层最大尺寸，超出时内容区域可滚动。

7. **gap**：浮层与触发元素的间距，默认根据是否有气泡尖角自动计算（有尖角时为 spineHeight + 2，无尖角时为 12）。
