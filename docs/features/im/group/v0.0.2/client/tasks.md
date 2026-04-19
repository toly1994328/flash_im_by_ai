# 搜索加群与入群审批 — 客户端任务清单

基于 [design.md](design.md) 设计，列出需要创建/修改的具体细节。

全局约束：
- 状态管理使用 Cubit（flutter_bloc），不使用 Event 模式
- SearchGroupPage 和 GroupNotificationsPage 用 StatefulWidget + setState，不用 Cubit
- GroupNotificationCubit 是应用级的，在 home_page 创建
- HTTP 请求用 Dio
- 系统用户 id=0

---

## 执行顺序

1. ✅ 任务 1 — group_models.dart 扩展（新增数据模型）
2. ✅ 任务 2 — group_repository.dart 扩展（新增 4 个 API 方法）
3. ✅ 任务 3 — ws_client.dart 扩展（新增 groupJoinRequestStream）
4. ✅ 任务 4 — group_notification_cubit.dart 新建（通知状态管理）
5. ✅ 任务 5 — search_group_page.dart 新建（搜索群聊页）
6. ✅ 任务 6 — group_notifications_page.dart 新建（群通知页）
7. ✅ 任务 7 — add_friend_page.dart 扩展（标题 + 搜索群聊入口）
8. ✅ 任务 8 — home_page.dart 扩展（注入 Cubit + 群通知入口 + 红点）
9. ✅ 任务 9 — flash_im_group.dart 导出新文件
10. ✅ 任务 10 — 编译验证
11. ✅ 任务 11 — group_chat_info_page.dart 新建（群聊详情页）
12. ✅ 任务 12 — ChatPage 群聊右上角跳转群详情 + GroupRepository 新增方法

---

## 任务 1：group_models.dart — 新增数据模型 `⬜ 待处理`

文件：`client/modules/flash_im_group/lib/src/data/group_models.dart`（修改）

### 1.1 GroupSearchResult `⬜`

```dart
class GroupSearchResult {
  final String id;
  final String? name;
  final String? avatar;
  final int? ownerId;
  final int groupNo;
  final int memberCount;
  final bool isMember;
  final bool joinVerification;
  final bool hasPendingRequest;

  const GroupSearchResult({...});

  factory GroupSearchResult.fromJson(Map<String, dynamic> json);
}
```

fromJson 字段映射：
- `id` ← json['id']
- `name` ← json['name']
- `avatar` ← json['avatar']
- `ownerId` ← json['owner_id']（int?）
- `groupNo` ← json['group_no']（int）
- `memberCount` ← json['member_count']（int）
- `isMember` ← json['is_member']（bool）
- `joinVerification` ← json['join_verification']（bool）
- `hasPendingRequest` ← json['has_pending_request']（bool）

### 1.2 JoinRequestItem `⬜`

```dart
class JoinRequestItem {
  final String id;
  final String conversationId;
  final String? groupName;
  final String? groupAvatar;
  final int userId;
  final String nickname;
  final String? avatar;
  final String? message;
  final int status;
  final DateTime createdAt;

  const JoinRequestItem({...});

  factory JoinRequestItem.fromJson(Map<String, dynamic> json);
}
```

fromJson 字段映射：
- `id` ← json['id']
- `conversationId` ← json['conversation_id']
- `groupName` ← json['group_name']
- `groupAvatar` ← json['group_avatar']
- `userId` ← json['user_id']（int）
- `nickname` ← json['nickname']
- `avatar` ← json['avatar']
- `message` ← json['message']
- `status` ← json['status']（int）
- `createdAt` ← DateTime.parse(json['created_at'])

---

## 任务 2：group_repository.dart — 新增 API 方法 `⬜ 待处理`

文件：`client/modules/flash_im_group/lib/src/data/group_repository.dart`（修改）

### 2.1 searchGroups `⬜`

```dart
/// 搜索群聊
Future<List<GroupSearchResult>> searchGroups(String keyword) async {
  final res = await _dio.get('/groups/search', queryParameters: {'keyword': keyword});
  return (res.data as List).map((e) => GroupSearchResult.fromJson(e)).toList();
}
```

### 2.2 joinGroup `⬜`

```dart
/// 申请入群，返回是否直接加入
Future<bool> joinGroup(String groupId, {String? message}) async {
  final res = await _dio.post('/groups/$groupId/join', data: {
    if (message != null) 'message': message,
  });
  return (res.data as Map<String, dynamic>)['auto_approved'] as bool;
}
```

### 2.3 handleJoinRequest `⬜`

```dart
/// 群主审批入群申请
Future<void> handleJoinRequest(String groupId, String requestId, {required bool approved}) async {
  await _dio.post('/groups/$groupId/join-requests/$requestId/handle', data: {
    'approved': approved,
  });
}
```

### 2.4 getJoinRequests `⬜`

```dart
/// 查询入群申请列表（群主视角）
Future<List<JoinRequestItem>> getJoinRequests() async {
  final res = await _dio.get('/groups/join-requests');
  return (res.data as List).map((e) => JoinRequestItem.fromJson(e)).toList();
}
```

---

## 任务 3：ws_client.dart — 新增 groupJoinRequestStream `⬜ 待处理`

文件：`client/modules/flash_im_core/lib/src/logic/ws_client.dart`（修改）

### 3.1 新增 StreamController `⬜`

在已有的 `_friendRemovedController` 下方新增：

```dart
final _groupJoinRequestController = StreamController<WsFrame>.broadcast();
Stream<WsFrame> get groupJoinRequestStream => _groupJoinRequestController.stream;
```

### 3.2 switch 分发新增 case `⬜`

在 `_onData` 方法的 switch 语句中新增：

```dart
case WsFrameType.GROUP_JOIN_REQUEST:
  _groupJoinRequestController.add(frame);
```

### 3.3 dispose 关闭 `⬜`

在 `dispose()` 方法中新增：

```dart
_groupJoinRequestController.close();
```

---

## 任务 4：group_notification_cubit.dart — 新建 `⬜ 待处理`

文件：`client/modules/flash_im_group/lib/src/logic/group_notification_cubit.dart`（新建）

### 4.1 GroupNotificationState `⬜`

```dart
class GroupNotificationState {
  final int pendingCount;
  final bool isLoading;

  const GroupNotificationState({this.pendingCount = 0, this.isLoading = false});

  GroupNotificationState copyWith({int? pendingCount, bool? isLoading});
}
```

### 4.2 GroupNotificationCubit `⬜`

```dart
class GroupNotificationCubit extends Cubit<GroupNotificationState> {
  final GroupRepository _repository;
  final Stream<WsFrame> _groupJoinRequestStream;
  StreamSubscription? _subscription;

  GroupNotificationCubit({
    required GroupRepository repository,
    required Stream<WsFrame> groupJoinRequestStream,
  });
```

逻辑步骤：
1. 构造函数中监听 `_groupJoinRequestStream`，每收到一帧 → `pendingCount++`
2. `loadPendingCount()` 方法：调 `_repository.getJoinRequests()`，过滤 status=0 的数量设为 pendingCount
3. `decrementCount()` 方法：审批后调用，pendingCount--（最小为 0）
4. `close()` 中取消订阅

---

## 任务 5：search_group_page.dart — 新建搜索群聊页 `⬜ 待处理`

文件：`client/modules/flash_im_group/lib/src/view/search_group_page.dart`（新建）

### 5.1 页面结构 `⬜`

```dart
class SearchGroupPage extends StatefulWidget {
  final GroupRepository repository;
  final String? baseUrl;

  const SearchGroupPage({super.key, required this.repository, this.baseUrl});
}
```

State 字段：
- `_searchController`: TextEditingController
- `_focusNode`: FocusNode（initState 中 requestFocus）
- `_results`: List<GroupSearchResult>
- `_isLoading`: bool
- `_keyword`: String
- `_debounce`: Timer?
- `_joiningIds`: Set<String>（防重复点击）

### 5.2 防抖搜索 `⬜`

```dart
void _onChanged(String value) {
  // 1. cancel 旧 timer
  // 2. trim 后为空 → 清空结果
  // 3. 设 _isLoading=true
  // 4. 新建 300ms Timer → _search(value)
}

Future<void> _search(String keyword) async {
  // 1. 调 repository.searchGroups(keyword)
  // 2. setState 更新 _results / _isLoading
  // 3. catch 异常显示错误
}
```

### 5.3 搜索结果列表项 `⬜`

每个列表项包含：
- 左侧：群头像（GroupAvatarWidget 解析 grid: 前缀，或 AvatarWidget）
- 中间：群名（关键词高亮）+ 成员数 + 群号
- 右侧：操作按钮（四种状态）

按钮状态逻辑：
| isMember | hasPendingRequest | joinVerification | 按钮 |
|----------|-------------------|------------------|------|
| true | — | — | "已加入"灰色标签 |
| false | true | — | "已申请"灰色标签 |
| false | false | false | "加入"蓝色按钮 |
| false | false | true | "申请"橙色按钮 |

### 5.4 入群对话框 `⬜`

```dart
void _showJoinDialog(GroupSearchResult group) {
  // showDialog:
  // - 标题：joinVerification ? '申请加入群聊' : '加入群聊'
  // - 内容：群信息预览（头像+群名+成员数）
  //         + joinVerification 时显示留言 TextField
  // - 按钮：取消 / 确认（joinVerification ? '发送申请' : '加入'）
  // - 确认后调 _requestJoin(group, message)
}
```

### 5.5 发送入群请求 `⬜`

```dart
Future<void> _requestJoin(GroupSearchResult group, String message) async {
  // 1. _joiningIds.add(group.id) + setState
  // 2. 调 repository.joinGroup(group.id, message: ...)
  // 3. autoApproved=true → SnackBar "已成功加入群聊"
  //    autoApproved=false → SnackBar "申请已发送，等待群主审批"
  // 4. 刷新搜索结果 _search(_keyword)
  // 5. finally: _joiningIds.remove + setState
}
```

### 5.6 build 方法 `⬜`

整体结构：
```
Scaffold
  AppBar: "搜索群聊"
  body: Column
    FlashSearchBar(onChanged: _onChanged, controller: _searchController)
    Expanded:
      _keyword.isEmpty → 空状态提示"输入群名或群号搜索"
      _isLoading → CircularProgressIndicator
      _results.isEmpty → "未找到相关群聊"
      else → ListView.builder(_results)
```

---

## 任务 6：group_notifications_page.dart — 新建群通知页 `⬜ 待处理`

文件：`client/modules/flash_im_group/lib/src/view/group_notifications_page.dart`（新建）

### 6.1 页面结构 `⬜`

```dart
class GroupNotificationsPage extends StatefulWidget {
  final GroupRepository repository;
  final String? baseUrl;

  const GroupNotificationsPage({super.key, required this.repository, this.baseUrl});
}
```

State 字段：
- `_requests`: List<JoinRequestItem>
- `_isLoading`: bool
- `_error`: String?

### 6.2 加载数据 `⬜`

```dart
Future<void> _load() async {
  // 1. setState isLoading=true
  // 2. 调 repository.getJoinRequests()
  // 3. 过滤 status=0 的待处理申请
  // 4. setState 更新 _requests / _isLoading
}
```

initState 中调用 `_load()`。

### 6.3 处理申请 `⬜`

```dart
Future<void> _handle(JoinRequestItem request, bool approved) async {
  // 1. 调 repository.handleJoinRequest(request.conversationId, request.id, approved: approved)
  // 2. SnackBar: approved ? '已同意' : '已拒绝'
  // 3. 重新加载列表 _load()
  // 4. 通知 GroupNotificationCubit 减少 pendingCount
}
```

### 6.4 列表项 UI `⬜`

每条申请显示：
- 左侧：申请者头像（AvatarWidget）
- 中间：申请者昵称 + "申请加入 {群名}" + 留言（如有）
- 右侧：status=0 时显示"拒绝"TextButton + "同意"ElevatedButton

### 6.5 空状态 `⬜`

无待处理申请时显示：图标 + "暂无群通知" + "当有人申请加入你的群聊时会显示在这里"

---

## 任务 7：add_friend_page.dart — 扩展 `⬜ 待处理`

文件：`client/modules/flash_im_friend/lib/src/view/add_friend_page.dart`（修改）

### 7.1 标题改为"加好友/群" `⬜`

```dart
appBar: AppBar(
  title: const Text('加好友/群'),
  ...
),
```

### 7.2 新增"搜索群聊"入口 `⬜`

在"创建群聊"入口下方新增：

```dart
_EntryItem(
  icon: Icons.search,
  iconColor: const Color(0xFFFF9800),
  title: '搜索群聊',
  subtitle: '搜索群名或群号加入群聊',
  onTap: () => onSearchGroup?.call(),
),
```

### 7.3 AddFriendPage 新增参数 `⬜`

新增 `onSearchGroup` 回调参数（由 home_page 注入跳转逻辑）：

```dart
class AddFriendPage extends StatelessWidget {
  final FriendRepository repository;
  final VoidCallback? onSearchGroup;  // 新增

  const AddFriendPage({
    super.key,
    required this.repository,
    this.onSearchGroup,
  });
}
```

---

## 任务 8：home_page.dart — 扩展 `⬜ 待处理`

文件：`client/lib/src/home/view/home_page.dart`（修改）

### 8.1 创建 GroupNotificationCubit `⬜`

在 `_HomePageState` 中新增：

```dart
late final GroupNotificationCubit _groupNotifCubit;
```

initState 中创建：
```dart
_groupNotifCubit = GroupNotificationCubit(
  repository: context.read<GroupRepository>(),
  groupJoinRequestStream: context.read<WsClient>().groupJoinRequestStream,
)..loadPendingCount();
```

dispose 中关闭：
```dart
_groupNotifCubit.close();
```

### 8.2 通讯录 Tab 新增"群通知"入口 `⬜`

在通讯录列表中（和"群聊"入口平级）新增"群通知"入口，带红点角标：

```dart
BlocBuilder<GroupNotificationCubit, GroupNotificationState>(
  bloc: _groupNotifCubit,
  builder: (context, state) {
    return _ContactEntry(
      icon: Icons.notifications_outlined,
      title: '群通知',
      badge: state.pendingCount > 0 ? state.pendingCount : null,
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => GroupNotificationsPage(
          repository: context.read<GroupRepository>(),
          baseUrl: AppConfig.baseUrl,
        ),
      )),
    );
  },
),
```

### 8.3 AddFriendPage 调用处传入新参数 `⬜`

找到跳转 AddFriendPage 的地方，补充 `groupRepository` 和 `baseUrl` 参数：

```dart
AddFriendPage(
  repository: context.read<FriendRepository>(),
  groupRepository: context.read<GroupRepository>(),  // 新增
  baseUrl: AppConfig.baseUrl,                        // 新增
)
```

### 8.4 GroupNotificationCubit 审批后刷新 `⬜`

GroupNotificationsPage 审批成功后需要通知 Cubit 减少 pendingCount。方案：
- GroupNotificationsPage 接收一个 `VoidCallback? onHandled` 回调
- 或者直接在 home_page 中通过 `_groupNotifCubit.decrementCount()` 处理

简单方案：GroupNotificationsPage pop 回来后，home_page 调用 `_groupNotifCubit.loadPendingCount()` 重新加载。

---

## 任务 9：flash_im_group.dart — 导出新文件 `⬜ 待处理`

文件：`client/modules/flash_im_group/lib/flash_im_group.dart`（修改）

### 9.1 新增导出 `⬜`

```dart
export 'src/logic/group_notification_cubit.dart';
export 'src/view/search_group_page.dart';
export 'src/view/group_notifications_page.dart';
```

### 9.2 flash_im_group pubspec.yaml 新增依赖 `⬜`

需要依赖 `flash_im_core`（用于 WsFrame 类型）和 `flutter_bloc`：

检查 pubspec.yaml 是否已有这些依赖，如果没有则添加。

---

## 任务 10：编译验证 `⬜ 待处理`

### 10.1 flutter analyze `⬜`

```bash
flutter analyze
```

确保无错误。

### 10.2 手动测试路径 `⬜`

1. 通讯录 → "加好友/群" → "搜索群聊" → 输入关键词 → 看到搜索结果
2. 搜索结果中点击"加入"（无需验证群）→ 确认 → Toast "已成功加入"
3. 搜索结果中点击"申请"（需验证群）→ 输入留言 → Toast "申请已发送"
4. 群主账号 → 通讯录 → "群通知"（红点）→ 看到申请列表 → 点击"同意"/"拒绝"
5. 验证审批后申请者搜索该群 → is_member=true

---

## 任务 11：group_chat_info_page.dart — 新建群聊详情页 `⬜ 待处理`

文件：`client/modules/flash_im_group/lib/src/view/group_chat_info_page.dart`（新建）

### 11.1 页面结构 `⬜`

```dart
class GroupChatInfoPage extends StatefulWidget {
  final GroupRepository repository;
  final String conversationId;
  final String? baseUrl;
  final String? currentUserId;
}
```

### 11.2 加载群详情 `⬜`

initState 调用 `repository.getGroupDetail(conversationId)`，获取群信息 + 成员列表。

### 11.3 成员网格 `⬜`

用 GridView 或 Wrap 展示成员头像 + 昵称（每行 5 个），头像用 AvatarWidget。

### 11.4 入群验证开关 `⬜`

群主（currentUserId == ownerId）显示 SwitchListTile "入群验证"，切换时调 `repository.updateGroupSettings`。
非群主不显示开关。

### 11.5 群信息展示 `⬜`

顶部展示：群名、群号、群头像、成员数。

---

## 任务 12：ChatPage + GroupRepository 扩展 `⬜ 待处理`

### 12.1 GroupRepository 新增 getGroupDetail / updateGroupSettings `⬜`

```dart
Future<Map<String, dynamic>> getGroupDetail(String groupId) async {
  final res = await _dio.get('/groups/$groupId/detail');
  return res.data as Map<String, dynamic>;
}

Future<void> updateGroupSettings(String groupId, {required bool joinVerification}) async {
  await _dio.put('/groups/$groupId/settings', data: {'join_verification': joinVerification});
}
```

### 12.2 ChatPage 群聊右上角跳转 `⬜`

替换原来的 SnackBar 占位，改为跳转 GroupChatInfoPage。需要在 ChatPage 新增 `onGroupInfo` 回调或直接传入 repository。

### 12.3 home_page.dart 传入参数 `⬜`

在 home_page 构造 ChatPage 时传入群详情所需的参数。

### 12.4 flash_im_group.dart 导出 `⬜`

新增 `export 'src/view/group_chat_info_page.dart';`
