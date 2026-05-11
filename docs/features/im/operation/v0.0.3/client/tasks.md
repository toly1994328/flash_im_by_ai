# @提及 — 客户端任务清单

基于 [design.md](design.md) 设计。改动分布在 flash_im_chat、flash_im_cache、flash_im_conversation。

---

## 执行顺序

### 阶段一：输入与发送

1. ✅ 任务 1 — ChatInput @检测 + membersFetcher + mentions 构建
2. ✅ 任务 2 — MentionPicker（MentionMember 模型）

### 阶段二：展示

3. ✅ 任务 3 — TextBubble @高亮渲染（RichText）
4. ✅ 任务 4 — 会话列表@提示标识

### 阶段三：验证

5. ✅ 任务 5 — flutter analyze

---

## 任务 1：ChatInput @检测 `✅`

文件：`client/modules/flash_im_chat/lib/src/view/chat_input.dart`（修改）

### 1.1 @字符检测 `✅`

监听 TextEditingController 变化，检测输入 `@` 时 push MemberPickerPage：

```dart
if (widget.isGroup) {
  final text = _controller.text;
  final offset = _controller.selection.baseOffset;
  if (offset > 0 && offset <= text.length && text[offset - 1] == '@') {
    _openMentionPicker();
  }
}
```

### 1.2 _openMentionPicker `✅`

通过 membersFetcher 异步获取群成员 → 转为 SelectableMember → push MemberPickerPage。
列表首项为"所有人"（id='all'，letter='!'，quickSelectIds 点击直接返回）。

### 1.3 选择后插入文本 `✅`

选择成员后，在 @ 位置插入 `昵称 `（带空格），记录 _MentionRecord（userId, offset, length）。

### 1.4 发送时构建 extra.mentions `✅`

```dart
final mentions = _mentionInfos.map((m) => {
  'user_id': m.userId,
  'offset': m.offset,
  'length': m.length,
}).toList();
```

### 1.5 新增参数 `✅`

```dart
final bool isGroup;
final String? groupAvatar;
final List<MentionMember>? groupMembers;
final Future<List<MentionMember>> Function()? membersFetcher;
final void Function(String content, List<Map<String, dynamic>>? mentions)? onSendWithMentions;
```

---

## 任务 2：MentionPicker `✅`

文件：`client/modules/flash_im_chat/lib/src/view/mention_picker.dart`（新建）

### 2.1 MentionMember 模型 `✅`

```dart
class MentionMember {
  final String userId;
  final String nickname;
  final String? avatar;
}
```

轻量模型，用于 ChatInput 和 MemberPickerPage 之间的数据传递。

---

## 任务 3：TextBubble @高亮渲染 `✅`

文件：`client/modules/flash_im_chat/lib/src/view/bubble/text_bubble.dart`（修改）

### 3.1 解析 mentions 构建 TextSpan `✅`

```dart
Widget _buildRichText(String content, List<MentionInfo>? mentions) {
  if (mentions == null || mentions.isEmpty) {
    return Text(content, style: ...);
  }
  // 按 offset 排序，分段构建 TextSpan
  // 普通文本：黑色
  // @文本：蓝色 #3B82F6 + FontWeight.w500
  return RichText(text: TextSpan(children: spans));
}
```

---

## 任务 4：会话列表@提示标识 `✅`

### 4.1 MentionMeRecord 结构体 `✅`

文件：`client/modules/flash_im_conversation/lib/src/data/conversation.dart`（修改）

```dart
enum MentionType { me, all }

class MentionMeRecord {
  final String messageId;
  final MentionType type;
}
```

### 4.2 SyncEngine 检测 @我 `✅`

文件：`client/modules/flash_im_cache/lib/src/sync_engine.dart`（修改）

`_handleChatMessage` 中解析 extra.mentions：
- 包含当前用户 ID → `onMentionMe(convId, "msgId:me")`
- 包含 "all" → `onMentionMe(convId, "msgId:all")`
- 优先检测 @我

### 4.3 ConversationListCubit 维护 mentionMeMap `✅`

文件：`client/modules/flash_im_conversation/lib/src/logic/conversation_list_cubit.dart`（修改）

```dart
final Map<String, List<MentionMeRecord>> _mentionMeMap = {};
void addMentionMe(String convId, MentionMeRecord record)
void clearMentionMe(String convId)  // 进入会话时清除
List<MentionMeRecord> getMentionMeRecords(String convId)
```

### 4.4 ConversationTile 展示 `✅`

文件：`client/modules/flash_im_conversation/lib/src/view/conversation_tile.dart`（修改）

- 有 MentionType.me → 优先显示 `[有人@我]`（多条时 `[有人@我×N]`）
- 只有 MentionType.all → 显示 `[@所有人]`
- 红色字体，在消息预览前面

---

## 任务 5：flutter analyze `✅`

```bash
cd client
flutter analyze
```

确保零错误。
