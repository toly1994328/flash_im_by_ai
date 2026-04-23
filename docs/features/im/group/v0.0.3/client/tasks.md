# 群成员管理与群详情 — 客户端任务清单

基于 [design.md](design.md) 设计，列出需要创建/修改的具体细节。

全局约束：
- GroupChatInfoPage 从最小版本扩展到完整版本，不新建页面（除群公告页和编辑群名页）
- 邀请入群复用 CreateGroupPage 的选人交互
- 踢人改用 MemberPickerPage（移除模式，红色勾选），不用 BottomSheet
- 群名编辑改为独立页面 EditGroupNamePage，不用 AlertDialog
- 新增 MemberPickerPage / SelectableMember / PinyinUtil 下沉到 flash_shared
- 退群/解散成功后 pop 回会话列表
- ChatPage 通过 groupDetailFetcher 异步拉取群详情，通过 groupInfoUpdateStream 实时同步
- UI 风格参考 flash-im-ui-style SKILL

---

## 执行顺序

1. ✅ 任务 1 — group_repository.dart 扩展（7 个新方法）
2. ✅ 任务 2 — group_chat_info_page.dart 大幅扩展（完整群详情页）
3. ✅ 任务 3 — group_announcement_page.dart 新建（群公告页）
4. ✅ 任务 4 — chat_page.dart 扩展（已解散状态 + 群公告横幅 + groupInfoUpdateStream 监听）
5. ✅ 任务 5 — home_page.dart 扩展（传入 groupDetailFetcher + 退群/解散导航）
6. ✅ 任务 6 — flash_im_group.dart 导出新文件
7. ✅ 任务 7 — MemberPickerPage / SelectableMember / PinyinUtil 下沉到 flash_shared
8. ✅ 任务 8 — WsClient 新增 groupInfoUpdateStream + ConversationListCubit 监听
9. ✅ 任务 9 — 编译验证

---

## 任务 1：group_repository.dart 扩展 `✅ 已完成`

文件：`client/modules/flash_im_group/lib/src/data/group_repository.dart`（修改）

### 1.1 addMembers `✅`

```dart
Future<int> addMembers(String groupId, List<int> memberIds) async {
  final res = await _dio.post('/groups/$groupId/members', data: {'member_ids': memberIds});
  return (res.data as Map<String, dynamic>)['added_count'] as int;
}
```

### 1.2 removeMember `✅`

```dart
Future<void> removeMember(String groupId, int userId) async {
  await _dio.delete('/groups/$groupId/members/$userId');
}
```

### 1.3 leaveGroup `✅`

```dart
Future<void> leaveGroup(String groupId) async {
  await _dio.post('/groups/$groupId/leave');
}
```

### 1.4 transferOwner `✅`

```dart
Future<void> transferOwner(String groupId, int newOwnerId) async {
  await _dio.put('/groups/$groupId/transfer', data: {'new_owner_id': newOwnerId});
}
```

### 1.5 disbandGroup `✅`

```dart
Future<void> disbandGroup(String groupId) async {
  await _dio.post('/groups/$groupId/disband');
}
```

### 1.6 updateAnnouncement `✅`

```dart
Future<void> updateAnnouncement(String groupId, String announcement) async {
  await _dio.put('/groups/$groupId/announcement', data: {'announcement': announcement});
}
```

### 1.7 updateGroup `✅`

```dart
Future<void> updateGroup(String groupId, {String? name, String? avatar}) async {
  await _dio.put('/groups/$groupId', data: {
    if (name != null) 'name': name,
    if (avatar != null) 'avatar': avatar,
  });
}
```

---

## 任务 2：group_chat_info_page.dart 大幅扩展 `✅ 已完成`

文件：`client/modules/flash_im_group/lib/src/view/group_chat_info_page.dart`（修改）

### 2.1 新增回调参数 `✅`

```dart
class GroupChatInfoPage extends StatefulWidget {
  // ... 已有参数
  final Future<List<SelectableMember>> Function()? friendsFetcher;  // 获取好友列表（邀请入群用）
  final VoidCallback? onLeaveOrDisband;  // 退群/解散后回调（pop 回会话列表）
}
```

### 2.2 成员网格扩展 +/- 按钮 `✅`

成员网格末尾追加操作按钮：
- "+"按钮（所有成员可见）：点击触发邀请入群流程
- "-"按钮（仅群主可见）：点击进入 MemberPickerPage 移除模式

操作按钮样式：虚线边框方形，和成员头像同尺寸。

### 2.3 邀请入群流程 `✅`

```dart
Future<void> _showInvitePage() async {
  // 1. 用 friendsFetcher 获取好友列表（转为 SelectableMember）
  // 2. 获取当前群成员 ID 集合作为 initialSelectedIds（预选不可取消）
  // 3. push CreateGroupPage，onCreated 回调中调 repository.addMembers（只传 memberIds，忽略 name）
  // 4. 成功后 Toast + 重新加载群详情
}
```

### 2.4 踢人流程（MemberPickerPage 移除模式） `✅`

```dart
void _showRemoveSheet() {
  // 1. 获取可移除成员列表（排除群主），转为 SelectableMember
  // 2. push MemberPickerPage（isRemoveMode=true, title='移除成员', confirmLabel='移除'）
  // 3. onConfirm 回调中逐个调 repository.removeMember
  // 4. 成功后 Toast + 重新加载群详情
}
```

### 2.5 群公告入口 `✅`

在群名/群号下方新增"群公告"设置项：
- 有公告时显示公告内容（单行省略）
- 无公告时显示"未设置"
- 点击 push GroupAnnouncementPage

### 2.6 群名编辑（EditGroupNamePage） `✅`

群主点击"群聊名称"行时 push EditGroupNamePage：
- 展示群头像 + 输入框（预填当前群名，maxLength: 30）
- 确认后返回新群名，调 `repository.updateGroup(groupId, name: newName)`
- 成功后重新加载群详情

普通成员点击无反应（或 SnackBar 提示"仅群主可修改群名"）。

### 2.7 群头像行（只展示不可修改） `✅`

群头像行展示当前群头像（宫格头像或普通头像），无 onTap 回调。箭头隐藏但保持占位（颜色设为 transparent）。

### 2.8 底部操作按钮（转让/解散独立按钮） `✅`

群主底部显示两个独立按钮（不走群管理菜单）：
- 蓝色"转让群主"按钮：点击弹出 BottomSheet 选择新群主 → 确认 → `repository.transferOwner` → Toast + 重新加载
- 红色"解散群聊"按钮：点击弹出二次确认对话框 → `repository.disbandGroup` → Toast + `onLeaveOrDisband` 回调

普通成员底部显示：
- 红色"退出群聊"按钮：点击弹出确认对话框 → `repository.leaveGroup` → `onLeaveOrDisband` 回调

### 2.9 非群主视图简化 `✅`

- 非群主不展示入群验证开关
- 非群主不展示群管理相关入口
- 无 onTap 的设置项箭头隐藏但保持占位

---

## 任务 3：group_announcement_page.dart 新建 `✅ 已完成`

文件：`client/modules/flash_im_group/lib/src/view/group_announcement_page.dart`（新建）

### 3.1 页面结构 `✅`

```dart
class GroupAnnouncementPage extends StatefulWidget {
  final GroupRepository repository;
  final String conversationId;
  final String? currentAnnouncement;
  final bool isOwner;
}
```

### 3.2 查看模式 `✅`

- 有公告：全屏展示公告内容（白色卡片 + 圆角 8）
- 无公告：居中"暂无群公告"+ 群主可见"发布群公告"按钮

### 3.3 编辑模式（仅群主） `✅`

- AppBar 右侧"编辑"按钮（群主可见）→ 切换到编辑模式
- TextField（maxLines: null, minLines: 8, maxLength: 200）
- AppBar 右侧变为"发布"按钮 → 调 `repository.updateAnnouncement` → pop 返回

---

## 任务 4：chat_page.dart 扩展 `✅ 已完成`

文件：`client/modules/flash_im_chat/lib/src/view/chat_page.dart`（修改）

### 4.1 新增参数 `✅`

```dart
class ChatPage extends StatefulWidget {
  // ... 已有参数
  final bool isDisband;                    // 群聊是否已解散（初始值）
  final String? announcement;              // 群公告内容（初始值）
  final Future<Map<String, dynamic>> Function()? groupDetailFetcher;  // 群详情获取器
}
```

### 4.2 groupDetailFetcher 异步拉取 `✅`

initState 中如果 `isGroup && groupDetailFetcher != null`，异步调用获取群详情：
- 从返回值中提取 `status`（解散状态）和 `announcement`（公告内容）
- 更新 `_isDisband` 和 `_announcement` 状态

### 4.3 groupInfoUpdateStream 实时监听 `✅`

initState 中监听 `WsClient.groupInfoUpdateStream`：
- 过滤 `conversationId` 匹配的帧
- 解析 GroupInfoUpdate proto 消息
- 动态更新 `_title`（群名）、`_announcement`（公告）、`_isDisband`（解散状态）

### 4.4 已解散状态 `✅`

如果 `_isDisband == true`：
- 输入框区域替换为灰色提示栏："该群聊已解散"（居中文字，灰色背景）
- AppBar 右上角不显示群详情按钮（`onGroupInfo` 不渲染）
- 历史消息仍可查看

### 4.5 群公告横幅 `✅`

如果 `_announcement` 不为空且 `isGroup == true` 且未解散：
- 在 AppBar 和消息列表之间显示黄色横幅
- 左侧喇叭图标 `Icons.campaign_outlined`（颜色 `#E6A817`）
- 中间公告文字（单行省略，颜色 `#666666`）
- 背景色 `#FFF9E6`，底部边框 `#EEE6CC`
- 点击触发 `onGroupInfo` 回调（跳转群详情页）

---

## 任务 5：home_page.dart 扩展 `✅ 已完成`

文件：`client/lib/src/home/view/home_page.dart`（修改）

### 5.1 ChatPage 构建传入 groupDetailFetcher `✅`

所有群聊 ChatPage 构建时传入 `groupDetailFetcher`：

```dart
groupDetailFetcher: conversation.isGroup ? () =>
    context.read<GroupRepository>().getGroupDetail(conversation.id) : null,
```

ChatPage 内部通过 groupDetailFetcher 异步拉取群详情（公告 + 解散状态），不再需要外部预先获取。

### 5.2 GroupChatInfoPage 传入新回调 `✅`

`onLeaveOrDisband` 回调：退群/解散成功后 pop 两层（GroupChatInfoPage + ChatPage）回到会话列表，并刷新会话列表。

`friendsFetcher` 回调：返回好友列表转换为 `List<SelectableMember>`（复用已有的 `_friendsToMembers` 方法）。

---

## 任务 6：flash_im_group.dart 导出 `✅ 已完成`

文件：`client/modules/flash_im_group/lib/flash_im_group.dart`（修改）

### 6.1 新增导出 `✅`

```dart
export 'src/view/group_announcement_page.dart';
export 'src/view/edit_group_name_page.dart';
```

---

## 任务 7：MemberPickerPage / SelectableMember / PinyinUtil 下沉到 flash_shared `✅ 已完成`

### 7.1 MemberPickerPage `✅`

文件：`client/modules/flash_shared/lib/src/member_picker_page.dart`（新建）

通用选人页面（微信风格）：
- 顶部已选头像横条（只展示新选的人，不含 lockedIds）+ 搜索框
- 按字母分组的列表 + 右侧索引栏
- 右上角操作按钮（完成/移除）
- 支持 `isRemoveMode`（红色勾选 + 红色按钮）
- `lockedIds` 成员在列表中灰色勾选不可点击
- 完成按钮数字只计新选人数

### 7.2 SelectableMember `✅`

文件：`client/modules/flash_shared/lib/src/selectable_member.dart`（新建）

```dart
class SelectableMember {
  final String id;
  final String nickname;
  final String? avatar;
  final String letter;  // 拼音首字母
}
```

### 7.3 PinyinUtil `✅`

文件：`client/modules/flash_shared/lib/src/pinyin_util.dart`（已有）

已迁移到 flash_shared，提供 `getFirstLetter(nickname)` 方法。

---

## 任务 8：WsClient 新增 groupInfoUpdateStream + ConversationListCubit 监听 `✅ 已完成`

### 8.1 WsClient 扩展 `✅`

文件：`client/modules/flash_im_core/lib/src/logic/ws_client.dart`（修改）

```dart
final _groupInfoUpdateController = StreamController<WsFrame>.broadcast();
Stream<WsFrame> get groupInfoUpdateStream => _groupInfoUpdateController.stream;
```

在 `_onData` 的 switch 中新增：
```dart
case WsFrameType.GROUP_INFO_UPDATE:
  _groupInfoUpdateController.add(frame);
```

### 8.2 ConversationListCubit 监听 `✅`

文件：`client/modules/flash_im_conversation/lib/src/logic/conversation_list_cubit.dart`（修改）

新增 `_handleGroupInfoUpdate` 方法：
- 监听 `groupInfoUpdateStream`
- 解析 GroupInfoUpdate proto 消息
- 更新匹配会话的 `name` 和 `avatar`
- emit 新状态

### 8.3 Proto 文件生成 `✅`

- `proto/ws.proto`：新增 `GROUP_INFO_UPDATE = 11`
- `proto/message.proto`：新增 `GroupInfoUpdate` 消息
- 生成对应的 Dart pb 文件

---

## 任务 9：编译验证 `✅ 已完成`

### 9.1 flutter analyze `✅`

```bash
flutter analyze
```

### 9.2 手动测试路径 `✅`

1. 群详情页 → "+"邀请 → 选人 → 邀请成功
2. 群详情页 → "-"踢人 → MemberPickerPage 移除模式 → 选择成员 → 移除成功
3. 群详情页 → "退出群聊" → 确认 → 返回会话列表
4. 群详情页 → "转让群主" → 选择 → 确认
5. 群详情页 → "解散群聊" → 确认 → 返回会话列表
6. 群详情页 → "群公告" → 查看/编辑/发布
7. 群详情页 → "群聊名称" → EditGroupNamePage → 修改成功
8. 已解散群 → 进入 ChatPage → 输入框禁用 + 提示栏 + 无详情按钮
9. 群聊有公告 → ChatPage 顶部黄色横幅 → 点击跳转群详情
10. WS 实时同步 → 修改群名后其他成员会话列表和 ChatPage 标题实时更新
11. WS 实时同步 → 修改群公告后其他成员 ChatPage 横幅实时更新
