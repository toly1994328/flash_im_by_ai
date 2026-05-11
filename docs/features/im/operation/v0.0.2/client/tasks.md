# 消息转发 — 客户端任务清单

基于 [design.md](design.md) 设计。改动分布在 flash_im_chat、flash_shared。

---

## 执行顺序

### 阶段一：基础设施

1. ✅ 任务 1 — MemberPickerPage 扩展（selectMode / onConfirmAsync / actions）
2. ✅ 任务 2 — MessageRepository 扩展（forwardMessage）

### 阶段二：转发功能

3. ✅ 任务 3 — ConversationPickerPage（会话选择器）
4. ✅ 任务 4 — ChatCubit 转发逻辑
5. ✅ 任务 5 — MessageActionMenu 扩展（转发菜单项）
6. ✅ 任务 6 — flutter analyze

---

## 任务 1：MemberPickerPage 扩展 `✅`

文件：`client/modules/flash_shared/lib/src/member_picker_page.dart`（修改）

### 1.1 新增 PickerSelectMode 枚举 `✅`

```dart
enum PickerSelectMode { single, multi }
```

### 1.2 新增参数 `✅`

```dart
final PickerSelectMode selectMode;
final bool showIndexBar;
final Future<bool> Function(MemberPickerResult result)? onConfirmAsync;
final List<Widget>? actions;
```

### 1.3 单选模式逻辑 `✅`

单选模式下点击直接触发 _handleConfirm，不显示勾选圆钮。

---

## 任务 2：MessageRepository 扩展 `✅`

文件：`client/modules/flash_im_chat/lib/src/data/message_repository.dart`（修改）

### 2.1 forwardMessage `✅`

```dart
Future<Map<String, dynamic>> forwardMessage({
  required String sourceConvId,
  required List<String> messageIds,
  required String targetConvId,
  required String forwardType,
}) async {
  final res = await _dio.post('/conversations/$sourceConvId/messages/forward', data: {
    'message_ids': messageIds,
    'target_conversation_id': targetConvId,
    'forward_type': forwardType,
  });
  return res.data as Map<String, dynamic>;
}
```

---

## 任务 3：ConversationPickerPage `✅`

文件：`client/modules/flash_im_chat/lib/src/view/conversation_picker_page.dart`（新建）

### 3.1 页面结构 `✅`

- 加载最近会话列表（GET /conversations）
- 转为 SelectableMember 传入 MemberPickerPage
- 默认单选，右上角切换多选
- showIndexBar=false

### 3.2 onConfirmAsync 确认弹窗 `✅`

- 弹出 AlertDialog，显示目标名称 + 消息预览（previewBuilder）
- 确认返回 true → pop，取消返回 false → 留在选择器

---

## 任务 4：ChatCubit 转发逻辑 `✅`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_cubit.dart`（修改）

### 4.1 forwardMessages `✅`

```dart
Future<void> forwardMessages({
  required List<String> messageIds,
  required String targetConvId,
  required String forwardType,
}) async {
  await _repository.forwardMessage(
    sourceConvId: conversationId,
    messageIds: messageIds,
    targetConvId: targetConvId,
    forwardType: forwardType,
  );
}
```

---

## 任务 5：MessageActionMenu 扩展 `✅`

文件：`client/modules/flash_im_chat/lib/src/view/message_action_menu.dart`（修改）

### 5.1 新增 MenuAction.forward `✅`

所有消息都可转发。

### 5.2 ChatPage 处理 forward action `✅`

打开 ConversationPickerPage，返回结果后调用 forwardMessages。

---

## 任务 6：flutter analyze `✅`

```bash
cd client
flutter analyze
```

确保零错误。
