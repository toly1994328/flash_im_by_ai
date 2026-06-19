---
name: flutter-confirm-dialog
description: 确认/删除等交互弹框统一使用 showTolyPopPicker 底部弹出样式。在需要弹出确认框、删除确认、操作选择时激活，确保交互风格一致。
metadata:
  model: manual
  last_modified: Wed, 18 Jun 2026 00:00:00 GMT

---

# 确认弹框规范

## 适用场景

- 删除确认（删除消息、删除文件、清除缓存）
- 危险操作确认（退群、解散群、注销账号）
- 二选一操作（下载/取消、清除/取消）

## 统一使用 showTolyPopPicker

**禁止使用** `showDialog` + `AlertDialog` 做确认弹框。

**统一使用** `showTolyPopPicker`（来自 `tolyui_feedback_modal` 包），底部弹出 action sheet 风格。

## 依赖

```dart
import 'package:tolyui_feedback_modal/tolyui_feedback_modal.dart';
```

## 基本用法

### 单按钮确认（删除/清除等危险操作）

```dart
showTolyPopPicker<bool>(
  context: context,
  title: const Text('确定删除这条消息？'),
  tasks: [
    TolyMenuItem(
      info: '删除',
      content: const Text('删除', style: TextStyle(color: Color(0xFFFF4D4F), fontSize: 16)),
      task: () {
        // 执行删除
        return true;
      },
    ),
  ],
);
```

### 多按钮选择

```dart
showTolyPopPicker<String>(
  context: context,
  title: const Text('选择操作'),
  tasks: [
    TolyMenuItem(
      info: 'download',
      content: const Text('下载到本地', style: TextStyle(fontSize: 16)),
      task: () {
        // 执行下载
        return 'download';
      },
    ),
    TolyMenuItem(
      info: 'share',
      content: const Text('分享', style: TextStyle(fontSize: 16)),
      task: () {
        // 执行分享
        return 'share';
      },
    ),
  ],
);
```

## 样式规范

| 元素 | 样式 |
|------|------|
| 弹框位置 | 底部弹出（action sheet 风格） |
| 标题 | `Text`，fontSize 默认 |
| 危险操作按钮 | 红色文字 `Color(0xFFFF4D4F)` |
| 普通操作按钮 | 默认黑色文字 |
| 取消按钮 | 自动附带，无需手动添加 |

## 注意事项

- ❌ 不要用 `showDialog` + `AlertDialog` 做确认弹框
- ❌ 不要用 `showModalBottomSheet` 自己画
- ✅ 统一用 `showTolyPopPicker`，保持全 App 一致体验
- ✅ 危险操作（删除/清除）按钮颜色用 `0xFFFF4D4F`
- ✅ `task` 回调里执行操作并返回结果
