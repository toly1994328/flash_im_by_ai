# 群聊（创建与加入） — 客户端任务清单

基于 [design.md](design.md) 设计，列出需要创建/修改的具体细节。

全局约束：
- 状态管理使用 Cubit，不使用 Event 模式
- 参考项目路径：`docs/ref/flash_im-main/app/`
- Protobuf Dart 代码已生成（`GROUP_JOIN_REQUEST` 帧类型 + `GroupJoinRequestNotification`）
- 群聊头像：GroupAvatarWidget 解析 grid: 前缀渲染九宫格，无 avatar 时显示绿色群图标
- 系统消息：sender_id=999999999 时显示居中灰色标签

---

## 执行顺序

1. ✅ 任务 1 — group_models.dart 新建
2. ✅ 任务 2 — conversation_repository.dart 扩展
3. ✅ 任务 3 — conversation.dart 模型修复
4. ✅ 任务 4 — ws_client.dart 扩展
5. ✅ 任务 5 — group_notification_cubit.dart 新建
6. ✅ 任务 6 — create_group_page.dart 新建
7. ✅ 任务 7 — search_group_page.dart 新建
8. ✅ 任务 8 — group_notifications_page.dart 新建
9. ✅ 任务 9 — private_chat_info_page.dart 新建
10. ✅ 任务 10 — conversation_tile.dart 群聊头像适配
11. ✅ 任务 11 — chat_page.dart 右上角按钮
12. ✅ 任务 12 — 模块导出调整
13. ✅ 任务 13 — home_page.dart 组装
14. ✅ 任务 14 — 编译验证
15. ✅ 任务 15 — GroupAvatarWidget 九宫格头像组件
16. ✅ 任务 16 — WxPopupMenuButton 弹出菜单
17. ✅ 任务 17 — 系统消息样式
18. ✅ 任务 18 — ConversationListCubit avatar 修复
10. ⬜ 任务 10 — conversation_tile.dart 修改（依赖任务 3）
11. ⬜ 任务 11 — chat_page.dart 修改（依赖任务 9）
12. ⬜ 任务 12 — 模块导出调整（依赖任务 1~9）
13. ⬜ 任务 13 — home_page.dart 组装（依赖任务 5~12）
14. ⬜ 任务 14 — 编译验证

---

## 任务 1：group_models.dart — 群聊数据模型 `⬜ 待处理`

文件：`client/modules/flash_im_conversation/lib/src/data/group_models.dart`（新建）

### 1.1 GroupSearchResult `⬜`

```dart
class GroupSearchResult {
  final String id;
  final String? name;
  final String? avatar;
  final int memberCount;
  final bool isMember;
  final bool joinVerification;

  const GroupSearchResult({...});

  factory GroupSearchResult.fromJson(Map<String, dynamic> json);
}
```

字段映射：`id`, `name`, `avatar`, `member_count`, `is_member`, `join_verification`

### 1.2 JoinGroupResponse `⬜`

```dart
class JoinGroupResponse {
  final bool autoApproved;
  final String? ownerId;
  final String? groupName;

  const JoinGroupResponse({...});

  factory JoinGroupResponse.fromJson(Map<String, dynamic> json);
}
```

字段映射：`auto_approved`, `owner_id`, `group_name`

### 1.3 MyGroupNotification `⬜`

```dart
class MyGroupNotification {
  final String id;
  final int userId;
  final String conversationId;
  final String? message;
  final int status;
  final String nickname;
  final String? avatar;
  final String? groupName;
  final DateTime createdAt;

  const MyGroupNotification({...});

  factory MyGroupNotification.fromJson(Map<String, dynamic> json);
}
```

字段映射：`id`, `user_id`(int), `conversation_id`, `message`, `status`, `nickname`, `avatar`, `group_name`, `created_at`(DateTime.parse)

### 1.4 CreateGroupResult `⬜`

```dart
/// CreateGroupPage 返回值
class CreateGroupResult {
  final String name;
  final List<int> memberIds;

  const CreateGroupResult({required this.name, required this.memberIds});
}
```

---

## 任务 2：conversation_repository.dart — 新增群聊方法 `⬜ 待处理`

文件：`client/modules/flash_im_conversation/lib/src/data/conversation_repository.dart`（修改）

### 2.1 新增 import `⬜`

```dart
import 'group_models.dart';
```

### 2.2 createGroup 方法 `⬜`

```dart
Future<Conversation> createGroup({
  required String name,
  required List<int> memberIds,
}) async {
  // POST /conversations, body: {"type": "group", "name": name, "member_ids": memberIds}
  // 返回 Conversation.fromJson(res.data)
}
```

### 2.3 searchGroups 方法 `⬜`

```dart
Future<List<GroupSearchResult>> searchGroups(String keyword, {int limit = 20}) async {
  // GET /conversations/search?keyword=xxx&limit=xxx
  // 返回 List<GroupSearchResult>
}
```

### 2.4 requestJoin 方法 `⬜`

```dart
Future<JoinGroupResponse> requestJoin(String conversationId, {String? message}) async {
  // POST /conversations/$conversationId/join, body: {"message": message}
  // 返回 JoinGroupResponse.fromJson(res.data)
}
```

### 2.5 handleJoinRequest 方法 `⬜`

```dart
Future<void> handleJoinRequest(
  String conversationId,
  String requestId, {
  required bool approved,
}) async {
  // POST /conversations/$conversationId/join-requests/$requestId/handle
  // body: {"approved": approved}
}
```

### 2.6 getMyJoinRequests 方法 `⬜`

```dart
Future<List<MyGroupNotification>> getMyJoinRequests({int limit = 20, int offset = 0}) async {
  // GET /conversations/my-join-requests?limit=xxx&offset=xxx
  // 返回 List<MyGroupNotification>
}
```

---

## 任务 3：conversation.dart — 群聊显示适配 `⬜ 待处理`

文件：`client/modules/flash_im_conversation/lib/src/data/conversation.dart`（修改）

### 3.1 displayAvatar 修复 `⬜`

当前 `displayAvatar` 只返回 `peerAvatar`（单聊对方头像）。群聊时应返回 `avatar`（conversations.avatar）。

```dart
/// 显示头像 URL
String? get displayAvatar =>
    type == 0 ? peerAvatar : avatar;
```

确认当前代码已经是这样。如果已正确则标记无需改动。

### 3.2 isGroup getter `⬜`

新增便捷 getter：

```dart
bool get isGroup => type == 1;
```

---

## 任务 4：ws_client.dart — 新增 groupJoinRequestStream `⬜ 待处理`

文件：`client/modules/flash_im_core/lib/src/logic/ws_client.dart`（修改）

### 4.1 新增 StreamController `⬜`

在现有的 `_friendRemovedController` 之后新增：

```dart
final _groupJoinRequestController = StreamController<WsFrame>.broadcast();
Stream<WsFrame> get groupJoinRequestStream => _groupJoinRequestController.stream;
```

### 4.2 新增 switch case `⬜`

在 `_onData` 方法的 switch 中，`FRIEND_REMOVED` 之后新增：

```dart
case WsFrameType.GROUP_JOIN_REQUEST:
  _groupJoinRequestController.add(frame);
```

### 4.3 dispose 中关闭 `⬜`

在 `dispose()` 方法中新增：

```dart
_groupJoinRequestController.close();
```

---

## 任务 5：group_notification_cubit.dart — 群通知状态管理 `⬜ 待处理`

文件：`client/modules/flash_im_conversation/lib/src/logic/group_notification_cubit.dart`（新建）

### 5.1 GroupNotificationState `⬜`

在同一文件中定义（或单独文件）：

```dart
class GroupNotificationState {
  final int pendingCount;
  const GroupNotificationState({this.pendingCount = 0});
}
```

### 5.2 GroupNotificationCubit `⬜`

```dart
class GroupNotificationCubit extends Cubit<GroupNotificationState> {
  final ConversationRepository _repository;
  StreamSubscription? _wsSub;

  GroupNotificationCubit({
    required ConversationRepository repository,
    WsClient? wsClient,
  }) : _repository = repository,
       super(const GroupNotificationState()) {
    _wsSub = wsClient?.groupJoinRequestStream.listen((_) => refresh());
  }

  // load(): 调用 _repository.getMyJoinRequests()，统计 status==0 的数量
  // refresh(): 同 load
  // decrementCount(): pendingCount > 0 时 -1
  // dispose(): _wsSub?.cancel()
}
```

参照参考项目 `cubit/group_notification_cubit.dart`。

---

## 任务 6：create_group_page.dart — 创建群聊页 `⬜ 待处理`

文件：`client/modules/flash_im_conversation/lib/src/view/create_group_page.dart`（新建）

参照参考项目 `screens/create_group_page.dart`。

### 6.1 页面结构 `⬜`

```dart
class CreateGroupPage extends StatefulWidget {
  final List<Friend> friends;
  final Set<String> initialSelectedIds;  // 从单聊详情页传入时预选对方

  const CreateGroupPage({
    required this.friends,
    this.initialSelectedIds = const {},
  });
}
```

注意：`Friend` 类型来自 `flash_im_friend`，但 `flash_im_conversation` 不依赖 `flash_im_friend`。解决方案：CreateGroupPage 接收泛型的好友数据，或者在 `home_page.dart` 中组装时传入。

实际做法：CreateGroupPage 定义在 `flash_im_conversation` 中，但 `Friend` 类型通过 import `flash_im_friend` 获取。需要在 `flash_im_conversation/pubspec.yaml` 中添加对 `flash_im_friend` 的依赖。

或者更好的做法：CreateGroupPage 不依赖 Friend 类型，而是接收一个简单的成员列表：

```dart
class SelectableMember {
  final String id;
  final String nickname;
  final String? avatar;
  const SelectableMember({required this.id, required this.nickname, this.avatar});
}
```

由调用方（home_page）将 `Friend` 转换为 `SelectableMember`。这样避免模块间依赖。

### 6.2 交互逻辑 `⬜`

1. `_nameController` — 群名输入
2. `_selectedIds` — 已选成员 ID 集合，初始化为 `initialSelectedIds`
3. `_canCreate` — `name.trim().isNotEmpty && _selectedIds.length >= 2`
4. `_toggleMember(id)` — 如果 id 在 `initialSelectedIds` 中则不可取消
5. 右上角 "创建(N)" 按钮，点击后 `Navigator.pop(context, CreateGroupResult(...))`

### 6.3 UI 布局 `⬜`

- AppBar: 标题 "创建群聊"，右上角 "创建(N)" TextButton
- Body: Column
  - 群名输入框（TextField + Icons.group 前缀图标）
  - 已选人数提示 "已选择 N 人"
  - 好友列表 ListView.builder，每项：头像 + 昵称 + 圆形 Checkbox
  - `initialSelectedIds` 中的成员 Checkbox 禁用（checked 但不可取消）

---

## 任务 7：search_group_page.dart — 搜索群聊页 `⬜ 待处理`

文件：`client/modules/flash_im_conversation/lib/src/view/search_group_page.dart`（新建）

参照参考项目 `presentation/search_group_page.dart`。

### 7.1 页面结构 `⬜`

```dart
class SearchGroupPage extends StatefulWidget {
  final ConversationRepository repository;
  const SearchGroupPage({required this.repository});
}
```

### 7.2 状态管理 `⬜`

- `_searchController` — 搜索输入
- `_results` — `List<GroupSearchResult>`
- `_isLoading` / `_error` / `_keyword`
- `_debounce` — `Timer?`，300ms 防抖
- `_joiningIds` — `Set<String>`，防止重复点击

### 7.3 搜索逻辑 `⬜`

1. `_onChanged(value)`: 取消旧 Timer，空值清空结果，非空设 300ms Timer 调 `_search`
2. `_search(keyword)`: 调用 `repository.searchGroups(keyword)`

### 7.4 入群逻辑 `⬜`

1. `_onGroupTap(group)`:
   - `isMember` → SnackBar "你已经是该群成员"
   - 否则 → `_showJoinDialog(group)`
2. `_showJoinDialog(group)`:
   - `joinVerification` 为 true → 显示留言输入框 + "发送申请" 按钮
   - `joinVerification` 为 false → 显示 "加入" 按钮
3. `_requestJoin(group, message)`:
   - 调用 `repository.requestJoin(group.id, message: ...)`
   - `autoApproved` → SnackBar "已成功加入群聊"，刷新搜索
   - `!autoApproved` → SnackBar "申请已发送，等待群主审批"

### 7.5 UI 布局 `⬜`

- AppBar: 搜索输入框（TextField）
- Body:
  - 空关键词 → 提示 "输入群名称搜索"
  - 加载中 → CircularProgressIndicator
  - 无结果 → "未找到相关群聊"
  - 有结果 → ListView，每项：群头像(默认 Icons.group) + 群名 + 成员数 + 操作按钮（已加入/加入/申请加入）

---

## 任务 8：group_notifications_page.dart — 群通知页 `⬜ 待处理`

文件：`client/modules/flash_im_conversation/lib/src/view/group_notifications_page.dart`（新建）

参照参考项目 `presentation/group_notifications_page.dart`。

### 8.1 页面结构 `⬜`

```dart
class GroupNotificationsPage extends StatefulWidget {
  final ConversationRepository repository;
  const GroupNotificationsPage({required this.repository});
}
```

### 8.2 数据加载 `⬜`

- `_load()`: 调用 `repository.getMyJoinRequests()`
- `_handle(request, approved)`: 调用 `repository.handleJoinRequest(...)` → SnackBar → `_load()` 刷新

### 8.3 UI 布局 `⬜`

- AppBar: "群通知"
- Body:
  - 加载中 → CircularProgressIndicator
  - 空列表 → "暂无群通知"
  - 有数据 → ListView，每项：
    - 左侧：申请者头像
    - 中间：昵称 + "申请加入 {群名}" + 留言（可选）
    - 右侧："拒绝" TextButton + "同意" ElevatedButton

---

## 任务 9：private_chat_info_page.dart — 单聊详情页 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/private_chat_info_page.dart`（新建）

参照参考项目 `im_chat/src/presentation/private_chat_info_page.dart`。

### 9.1 页面结构 `⬜`

```dart
class PrivateChatInfoPage extends StatelessWidget {
  final String peerName;
  final String? peerAvatar;
  final String? peerUserId;
  final VoidCallback? onAddMember;  // 点击"+"时回调

  const PrivateChatInfoPage({...});
}
```

### 9.2 UI 布局 `⬜`

- AppBar: "聊天详情"
- Body: ListView
  - 顶部成员区域（白色背景 Container）：
    - Wrap 布局，每行 5 个 tile
    - 第 1 个 tile：对方头像 + 昵称
    - 第 2 个 tile："+" 虚线框按钮，点击触发 `onAddMember`
  - 间距
  - （后续版本可加：消息免打扰、置顶聊天、清空记录等设置项）

参照参考项目的 `_buildMemberSection` 方法实现网格布局。

---

## 任务 10：conversation_tile.dart — 群聊头像适配 `⬜ 待处理`

文件：`client/modules/flash_im_conversation/lib/src/view/conversation_tile.dart`（修改）

### 10.1 头像适配 `⬜`

当前 `_buildAvatarImage` 只用 `conversation.peerAvatar`。群聊时应使用 `conversation.displayAvatar`，如果为 null 或以 `grid:` 开头则显示默认群图标。

```dart
Widget _buildAvatarImage() {
  if (conversation.isSkeleton) {
    return Container(...);  // 保持不变
  }
  if (conversation.isGroup) {
    // 本版本用默认群图标
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.group, color: Color(0xFF999999), size: 24),
    );
  }
  return AvatarWidget(avatar: conversation.peerAvatar, size: 44, borderRadius: 6);
}
```

---

## 任务 11：chat_page.dart — 右上角按钮 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/chat_page.dart`（修改）

### 11.1 新增参数 `⬜`

ChatPage 新增可选参数：

```dart
class ChatPage extends StatefulWidget {
  // ... 现有参数 ...
  final bool isGroup;           // 新增：是否群聊
  final String? peerUserId;     // 新增：单聊对方 ID（详情页用）
  final VoidCallback? onAddMember;  // 新增：单聊详情页"+"回调
}
```

### 11.2 AppBar actions `⬜`

在 AppBar 中新增 actions：

```dart
appBar: AppBar(
  title: Text(widget.peerName),
  actions: [
    if (!widget.isGroup)
      IconButton(
        icon: Icon(Icons.more_horiz),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PrivateChatInfoPage(
              peerName: widget.peerName,
              peerAvatar: widget.peerAvatar,
              peerUserId: widget.peerUserId,
              onAddMember: widget.onAddMember,
            ),
          ),
        ),
      ),
    if (widget.isGroup)
      IconButton(
        icon: Icon(Icons.group),
        onPressed: () {
          // 本版本暂不实现群详情页，显示 SnackBar 提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('群详情页将在下一版本实现')),
          );
        },
      ),
  ],
),
```

### 11.3 新增 import `⬜`

```dart
import 'private_chat_info_page.dart';
```

---

## 任务 12：模块导出调整 `⬜ 待处理`

### 12.1 flash_im_conversation 导出 `⬜`

文件：`client/modules/flash_im_conversation/lib/flash_im_conversation.dart`（修改）

新增导出：

```dart
export 'src/data/group_models.dart';
export 'src/logic/group_notification_cubit.dart';
export 'src/view/create_group_page.dart';
export 'src/view/search_group_page.dart';
export 'src/view/group_notifications_page.dart';
```

### 12.2 flash_im_chat 导出 `⬜`

文件：`client/modules/flash_im_chat/lib/flash_im_chat.dart`（修改）

新增导出：

```dart
export 'src/view/private_chat_info_page.dart';
```

---

## 任务 13：home_page.dart — 入口组装 `⬜ 待处理`

文件：`client/lib/src/home/view/home_page.dart`（修改）

### 13.1 新增 import `⬜`

```dart
import 'package:flash_im_conversation/flash_im_conversation.dart';
// CreateGroupPage, SearchGroupPage, GroupNotificationsPage, GroupNotificationCubit, CreateGroupResult, SelectableMember 等
```

### 13.2 消息 Tab 右上角"+"按钮 `⬜`

在 `_buildMessageTab` 的 AppBar 中新增 actions：

```dart
actions: [
  IconButton(
    icon: Icon(Icons.group_add_outlined),
    onPressed: () => _openCreateGroup(context),
  ),
],
```

`_openCreateGroup` 方法：
1. 从 `FriendCubit.state.friends` 获取好友列表
2. 转换为 `SelectableMember` 列表
3. `Navigator.push(CreateGroupPage(friends: members))`
4. 拿到 `CreateGroupResult` 后调用 `ConversationRepository.createGroup`
5. 成功后 push `ChatPage`

### 13.3 通讯录 Tab 新增入口 `⬜`

在 `_buildContactsTab` 中，FriendListPage 之上或之内新增两个入口：
- "搜索群聊" → push `SearchGroupPage`
- "群通知" → push `GroupNotificationsPage`（带红点角标，数据来自 `GroupNotificationCubit`）

具体做法：在 FriendListPage 的 header 区域（现有的 "添加朋友" 入口旁边）新增 "搜索群聊" 和 "群通知" 入口。

### 13.4 GroupNotificationCubit 初始化 `⬜`

在 `initState` 中创建 `GroupNotificationCubit`：

```dart
late final GroupNotificationCubit _groupNotifCubit;

@override
void initState() {
  super.initState();
  // ... 现有初始化 ...
  _groupNotifCubit = GroupNotificationCubit(
    repository: context.read<ConversationRepository>(),
    wsClient: context.read<WsClient>(),
  )..load();
}
```

### 13.5 ChatPage 调用适配 `⬜`

修改 `onConversationTap` 和 `_startChatWithFriend` 中的 ChatPage 构造，传入新参数：

```dart
ChatPage(
  conversationId: conversation.id,
  peerName: conversation.displayName,
  peerAvatar: conversation.displayAvatar,
  baseUrl: AppConfig.baseUrl,
  isGroup: conversation.isGroup,                    // 新增
  peerUserId: conversation.peerUserId,              // 新增
  onAddMember: () => _createGroupFromChat(context, conversation),  // 新增
)
```

`_createGroupFromChat` 方法：
1. 从 `FriendCubit.state.friends` 获取好友列表
2. 转换为 `SelectableMember`
3. `Navigator.push(CreateGroupPage(friends: members, initialSelectedIds: {conversation.peerUserId!}))`
4. 拿到结果后调 `createGroup` → push `ChatPage`

---

## 任务 14：编译验证 `⬜ 待处理`

### 14.1 静态分析 `⬜`

```bash
flutter analyze
```

在 `client/` 目录下执行，确认无错误。

### 14.2 手动测试路径 `⬜`

1. 消息 Tab "+" → 创建群聊页 → 选好友 + 输入群名 → 创建 → 进入群聊 ChatPage
2. 单聊 ChatPage → 右上角"..." → 单聊详情页 → "+" → 创建群聊页（对方预选中）→ 创建
3. 会话列表 → 群聊显示群名称 + 默认群图标
4. 通讯录 → 搜索群聊 → 输入关键词 → 看到结果 → 点击加入
5. 通讯录 → 群通知 → 看到待处理申请 → 同意/拒绝
6. 群聊中发消息 → 其他成员收到并显示发送者昵称

## 任务 15：GroupAvatarWidget 九宫格头像组件 `✅ 已完成`

- ✅ `flash_shared/lib/src/group_avatar_widget.dart` 新建
- ✅ GroupAvatarMember（id + avatarUrl）+ GroupAvatarWidget（1~9人宫格布局）
- ✅ 内部用 AvatarWidget 渲染每个格子（支持 identicon:）
- ✅ conversation_tile.dart 解析 `grid:` 前缀调用 GroupAvatarWidget
- ✅ flash_shared.dart 导出

## 任务 16：WxPopupMenuButton 弹出菜单 `✅ 已完成`

- ✅ `flash_shared/lib/src/popup_menu_button.dart` 新建
- ✅ WxMenuItem（icon + text + onTap）+ WxPopupMenuButton（Overlay + 尖角气泡 + 缩放动画）
- ✅ home_page.dart 消息 Tab 右上角改为 WxPopupMenuButton（发起群聊 / 添加朋友 / 扫一扫）
- ✅ flash_shared.dart 导出
- ✅ client/pubspec.yaml 新增 flash_shared 直接依赖

## 任务 17：系统消息样式 `✅ 已完成`

- ✅ `message.dart` 新增 `bool get isSystem => senderId == '999999999'`
- ✅ `message_bubble.dart` build 方法开头判断 isSystem，渲染居中灰色圆角标签

## 任务 18：ConversationListCubit avatar 修复 `✅ 已完成`

- ✅ `conversation_list_cubit.dart` _handleUpdate 中更新已有会话时补充 `avatar: c.avatar`
- ✅ 修复群聊收到新消息后宫格头像丢失的问题
