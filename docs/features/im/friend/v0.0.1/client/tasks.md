# IM Friend v0.0.1 — 客户端任务清单

基于 [design.md](./design.md) 设计，列出需要创建/修改的具体细节。

全局约束：
- 状态管理使用 Cubit，不使用 Event 模式
- 参考 flash_im_conversation 模块结构（data/logic/view 三层）
- WsClient 扩展遵循现有 switch 分发模式
- `client/lib/playground/` 已废弃，不引用不修改

---

## 执行顺序

1. ✅ 任务 1 — proto 重新生成 Dart 文件（无依赖）
2. ✅ 任务 2 — WsClient 扩展三条好友 Stream（依赖任务 1）
3. ✅ 任务 3 — flash_im_friend 模块骨架（依赖任务 2）
   - ✅ 3.1 pubspec.yaml
   - ✅ 3.2 data/friend.dart
   - ✅ 3.3 data/friend_repository.dart
   - ✅ 3.4 logic/friend_state.dart
   - ✅ 3.5 logic/friend_cubit.dart
   - ✅ 3.6 flash_im_friend.dart
4. ✅ 任务 4 — 好友列表页 + 好友 Tile（依赖任务 3）
   - ✅ 4.1 view/friend_tile.dart
   - ✅ 4.2 view/friend_list_page.dart
5. ✅ 任务 5 — 好友申请页（依赖任务 3）
6. ✅ 任务 6 — 用户搜索页（依赖任务 3）
7. ✅ 任务 7 — 主应用集成（依赖任务 3~6）
   - ✅ 7.1 client/pubspec.yaml 新增依赖
   - ✅ 7.2 main.dart 注册 FriendRepository + FriendCubit
   - ✅ 7.3 home_page.dart 改造通讯录 Tab
8. ✅ 任务 8 — 编译验证
9. ✅ 任务 9 — IndexedContactList + 拼音索引（依赖任务 4）
10. ✅ 任务 10 — FriendDetailPage 好友详情页（依赖任务 4）
11. ✅ 任务 11 — 好友申请页 TabBar + 侧滑删除改造（依赖任务 5）
12. ✅ 任务 12 — AddFriendPage 添加朋友主页（依赖任务 6）
13. ✅ 任务 13 — FlashSearchBar / FlashSearchInput 共享组件
14. ✅ 任务 14 — qr_flutter 依赖 + AddFriendPage 个人二维码
15. ✅ 任务 15 — FriendRequestPage AppBar 添加朋友按钮 + 搜索 hint 更新 + 导航调整
16. ✅ 任务 16 — UserProfilePage + SendRequestPage + 搜索流程
17. ✅ 任务 17 — ScanPage 扫码添加好友（依赖任务 12）重构

---

## 任务 1：proto 重新生成 Dart 文件 `⬜ 待处理`

文件：`client/modules/flash_im_core/lib/src/data/proto/` 下所有 `.pb.dart` / `.pbenum.dart`（重新生成）

### 1.1 执行 protoc 生成 `⬜`

ws.proto 已新增 FRIEND_REQUEST(7) / FRIEND_ACCEPTED(8) / FRIEND_REMOVED(9) 帧类型和三个 Notification 消息。需要重新生成 Dart 文件。

```bash
protoc --proto_path=proto --dart_out=client/modules/flash_im_core/lib/src/data/proto proto/ws.proto proto/message.proto
```

protoc 路径：`C:\toly\SDK\protoc\bin\protoc.exe`
dart plugin 已全局安装。

生成后验证 `ws.pbenum.dart` 包含 `FRIEND_REQUEST`、`FRIEND_ACCEPTED`、`FRIEND_REMOVED`，`ws.pb.dart` 包含 `FriendRequestNotification`、`FriendAcceptedNotification`、`FriendRemovedNotification` 类。

### 1.2 更新 flash_im_core 导出 `⬜`

文件：`client/modules/flash_im_core/lib/flash_im_core.dart`

当前已导出 `ws.pb.dart` 和 `ws.pbenum.dart`，重新生成后新类型自动可用，无需额外修改。确认即可。

---

## 任务 2：WsClient 扩展 `⬜ 待处理`

文件：`client/modules/flash_im_core/lib/src/logic/ws_client.dart`（修改）

### 2.1 新增三个 StreamController `⬜`

在现有 `_conversationUpdateController` 下方新增：

```dart
final _friendRequestController = StreamController<WsFrame>.broadcast();
final _friendAcceptedController = StreamController<WsFrame>.broadcast();
final _friendRemovedController = StreamController<WsFrame>.broadcast();

Stream<WsFrame> get friendRequestStream => _friendRequestController.stream;
Stream<WsFrame> get friendAcceptedStream => _friendAcceptedController.stream;
Stream<WsFrame> get friendRemovedStream => _friendRemovedController.stream;
```

### 2.2 扩展 _onData switch 分发 `⬜`

在 `_onData` 方法的 switch 块中新增三个 case：

```dart
case WsFrameType.FRIEND_REQUEST:
  _friendRequestController.add(frame);
case WsFrameType.FRIEND_ACCEPTED:
  _friendAcceptedController.add(frame);
case WsFrameType.FRIEND_REMOVED:
  _friendRemovedController.add(frame);
```

### 2.3 dispose 中关闭新 Controller `⬜`

```dart
_friendRequestController.close();
_friendAcceptedController.close();
_friendRemovedController.close();
```


---

## 任务 3：flash_im_friend 模块骨架 `⬜ 待处理`

### 3.1 pubspec.yaml `⬜`

文件：`client/modules/flash_im_friend/pubspec.yaml`（新建）

```yaml
name: flash_im_friend
description: Flash IM 好友模块
version: 0.0.1
publish_to: none

environment:
  sdk: ^3.11.1
  flutter: ">=1.17.0"

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.8.0+1
  flutter_bloc: ^8.1.6
  equatable: ^2.0.7
  flash_im_core:
    path: ../flash_im_core
  flash_shared:
    path: ../flash_shared
  lpinyin: ^2.0.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

### 3.2 data/friend.dart `⬜`

文件：`client/modules/flash_im_friend/lib/src/data/friend.dart`（新建）

```dart
/// 好友（带用户信息）
class Friend {
  final String friendId;
  final String nickname;
  final String? avatar;
  final String? bio;
  final DateTime createdAt;

  // fromJson: 字段对应后端 FriendWithProfile
}

/// 好友申请（带申请者/被申请者信息）
class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String? message;
  final int status;       // 0:pending 1:accepted 2:rejected
  final String nickname;
  final String? avatar;
  final DateTime createdAt;
  final DateTime updatedAt;

  // fromJson: 后端 FriendRequestWithProfile（flatten 结构）
}

/// 搜索结果用户
class SearchUser {
  final String id;
  final String nickname;
  final String? avatar;

  // fromJson
}
```

### 3.3 data/friend_repository.dart `⬜`

文件：`client/modules/flash_im_friend/lib/src/data/friend_repository.dart`（新建）

```dart
class FriendRepository {
  final Dio _dio;
  FriendRepository({required Dio dio}) : _dio = dio;
```

方法：

- `Future<List<SearchUser>> searchUsers(String keyword, {int limit = 20})`
  1. GET /api/users/search?keyword=&limit=
  2. 解析 data 数组 → List<SearchUser>

- `Future<FriendRequest> sendRequest(String toUserId, {String? message})`
  1. POST /api/friends/requests {to_user_id, message}
  2. 解析 data → FriendRequest

- `Future<List<FriendRequest>> getReceivedRequests({int limit = 20, int offset = 0})`
  1. GET /api/friends/requests/received?limit=&offset=

- `Future<List<FriendRequest>> getSentRequests({int limit = 20, int offset = 0})`
  1. GET /api/friends/requests/sent?limit=&offset=

- `Future<void> acceptRequest(String requestId)`
  1. POST /api/friends/requests/:id/accept

- `Future<void> rejectRequest(String requestId)`
  1. POST /api/friends/requests/:id/reject

- `Future<List<Friend>> getFriends({int limit = 20, int offset = 0})`
  1. GET /api/friends?limit=&offset=

- `Future<void> deleteFriend(String friendId)`
  1. DELETE /api/friends/:id

- `Future<void> deleteRequest(String requestId)`
  1. DELETE /api/friends/requests/:id

### 3.4 logic/friend_state.dart `⬜`

文件：`client/modules/flash_im_friend/lib/src/logic/friend_state.dart`（新建）

```dart
class FriendState extends Equatable {
  final List<Friend> friends;
  final List<FriendRequest> receivedRequests;
  final List<FriendRequest> sentRequests;  // 我发送的申请
  final int pendingCount;          // 未读申请数（红点）
  final bool isLoading;
  final String? error;

  // copyWith
  // props: [friends, receivedRequests, sentRequests, pendingCount, isLoading, error]
}
```

### 3.5 logic/friend_cubit.dart `⬜`

文件：`client/modules/flash_im_friend/lib/src/logic/friend_cubit.dart`（新建）

```dart
class FriendCubit extends Cubit<FriendState> {
  final FriendRepository _repository;
  final WsClient _wsClient;
  StreamSubscription? _requestSub;
  StreamSubscription? _acceptedSub;
  StreamSubscription? _removedSub;
```

构造函数：
1. 订阅 `_wsClient.friendRequestStream` → `_handleFriendRequest`
2. 订阅 `_wsClient.friendAcceptedStream` → `_handleFriendAccepted`
3. 订阅 `_wsClient.friendRemovedStream` → `_handleFriendRemoved`

方法：

- `Future<void> loadFriends()`
  1. emit loading
  2. repository.getFriends()
  3. emit 更新 friends 列表

- `Future<void> loadReceivedRequests()`
  1. repository.getReceivedRequests()
  2. emit 更新 receivedRequests + pendingCount

- `Future<void> acceptRequest(String requestId)`
  1. repository.acceptRequest(requestId)
  2. 从 receivedRequests 移除，pendingCount--
  3. 重新 loadFriends()（新好友出现）

- `Future<void> rejectRequest(String requestId)`
  1. repository.rejectRequest(requestId)
  2. 从 receivedRequests 移除，pendingCount--

- `Future<void> deleteFriend(String friendId)`
  1. repository.deleteFriend(friendId)
  2. 从 friends 列表移除

- `Future<void> loadSentRequests()`
  1. repository.getSentRequests()
  2. emit 更新 sentRequests 列表

- `Future<void> deleteRequest(String requestId)`
  1. repository.deleteRequest(requestId)
  2. 从 receivedRequests 或 sentRequests 中移除对应条目

- `void _handleFriendRequest(WsFrame frame)`
  1. 解析 FriendRequestNotification
  2. 构造 FriendRequest 插入 receivedRequests 头部
  3. pendingCount++

- `void _handleFriendAccepted(WsFrame frame)`
  1. 解析 FriendAcceptedNotification
  2. 构造 Friend 插入 friends 列表
  3. （对方接受了我的申请，好友列表新增）

- `void _handleFriendRemoved(WsFrame frame)`
  1. 解析 FriendRemovedNotification
  2. 从 friends 列表移除对应 friendId

- `void clearPendingCount()`
  1. pendingCount = 0（进入申请页时调用）

- `close()`: 取消三个 StreamSubscription

### 3.6 flash_im_friend.dart `⬜`

文件：`client/modules/flash_im_friend/lib/flash_im_friend.dart`（新建）

```dart
library;

export 'src/data/friend.dart';
export 'src/data/friend_repository.dart';
export 'src/logic/friend_cubit.dart';
export 'src/logic/friend_state.dart';
export 'src/utils/pinyin_helper.dart';
export 'src/view/friend_list_page.dart';
export 'src/view/friend_request_page.dart';
export 'src/view/friend_detail_page.dart';
export 'src/view/user_search_page.dart';
export 'src/view/indexed_contact_list.dart';
export 'src/view/friend_tile.dart';
```

---

## 任务 4：好友列表页 + 好友 Tile `⬜ 待处理`

### 4.1 view/friend_tile.dart `⬜`

文件：`client/modules/flash_im_friend/lib/src/view/friend_tile.dart`（新建）

单个好友列表项组件：

```dart
class FriendTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
```

布局：
- 左侧 AvatarWidget（flash_shared）
- 中间 nickname + bio
- 整行可点击（onTap）、长按（onLongPress → 删除确认）

### 4.2 view/friend_list_page.dart `⬜`

文件：`client/modules/flash_im_friend/lib/src/view/friend_list_page.dart`（新建）

通讯录 Tab 的内容页面：

```dart
class FriendListPage extends StatelessWidget {
  final void Function(Friend friend)? onFriendTap;
  final VoidCallback? onAddFriendTap;
  final VoidCallback? onRequestsTap;
```

结构：
- AppBar：标题"通讯录"，右上角"+"按钮（onAddFriendTap → 跳转搜索页）
- 顶部三个入口：新的朋友（功能完整，显示 pendingCount 红点）+ 群通知（占位）+ 我的群聊（占位）
- 列表：使用 IndexedContactList 展示好友（拼音字母索引 + 吸顶标题 + 右侧索引栏）
- 空状态：暂无好友
- 下拉刷新：RefreshIndicator → cubit.loadFriends()
- 点击好友：跳转 FriendDetailPage（非直接进聊天）

---

## 任务 5：好友申请页 `⬜ 待处理`

文件：`client/modules/flash_im_friend/lib/src/view/friend_request_page.dart`（新建）

```dart
class FriendRequestPage extends StatefulWidget
```

结构：
- AppBar：标题"好友申请"
- TabBar 双 Tab：好友申请（收到的）/ 我的申请（发送的）
- initState 中调用 cubit.loadReceivedRequests() + cubit.loadSentRequests() + cubit.clearPendingCount()
- 好友申请 Tab：每条申请显示头像 + 昵称 + 留言 + 接受/拒绝按钮
- 我的申请 Tab：每条申请显示头像 + 昵称 + 留言 + 状态（待处理/已接受/已拒绝）
- 两个 Tab 都支持侧滑删除（Dismissible → cubit.deleteRequest(id)）
- 接受：cubit.acceptRequest(id)，成功后 Toast "已添加"
- 拒绝：cubit.rejectRequest(id)，条目消失
- 空状态：暂无好友申请

---

## 任务 6：用户搜索页 `⬜ 待处理`

文件：`client/modules/flash_im_friend/lib/src/view/user_search_page.dart`（新建）

```dart
class UserSearchPage extends StatefulWidget
```

内部管理搜索状态（StatefulWidget，不用 Cubit）：

- AppBar：搜索输入框（TextField + 搜索按钮）
- 搜索结果列表：头像 + 昵称 + "添加"按钮
- 点击"添加"：弹出留言输入对话框 → repository.sendRequest(userId, message)
- 成功后 Toast "申请已发送"，按钮变为"已发送"（灰色不可点击）
- 搜索为空：提示"未找到用户"
- 防抖：输入停止 500ms 后自动搜索（或手动点击搜索）

---

## 任务 7：主应用集成 `⬜ 待处理`

### 7.1 client/pubspec.yaml `⬜`

文件：`client/pubspec.yaml`（修改）

在 dependencies 中新增：

```yaml
  flash_im_friend:
    path: modules/flash_im_friend
```

### 7.2 main.dart 注册 `⬜`

文件：`client/lib/main.dart`（修改）

新增：

```dart
import 'package:flash_im_friend/flash_im_friend.dart';

// 在 main() 中创建
final friendRepo = FriendRepository(dio: httpClient.dio);

// 在 runApp 的 MultiRepositoryProvider 中新增
RepositoryProvider.value(value: friendRepo),

// 在 BlocProvider.value 后新增 FriendCubit
BlocProvider(
  create: (_) => FriendCubit(
    repository: friendRepo,
    wsClient: wsClient,
  ),
),
```

注意：FriendCubit 需要在 WsClient connect 之前创建，确保 Stream 订阅不丢帧。

### 7.3 home_page.dart 改造通讯录 Tab `⬜`

文件：`client/lib/src/home/view/home_page.dart`（修改）

1. import flash_im_friend
2. 替换通讯录 Tab 占位文本为 FriendListPage：

```dart
// 原来：
const Center(child: Text('暂无联系人', ...))

// 改为：
FriendListPage(
  onFriendTap: (friend) { /* 创建会话 → push ChatPage */ },
  onAddFriendTap: () { /* push UserSearchPage */ },
  onRequestsTap: () { /* push FriendRequestPage */ },
)
```

3. onFriendTap 实现：
   - 跳转 FriendDetailPage（微信风格详情页：头像+昵称+签名 + 发消息/删除好友）
   - FriendDetailPage 中"发消息"：调用 ConversationRepository.createPrivate → push ChatPage
   - FriendDetailPage 中"删除好友"：确认对话框 → cubit.deleteFriend() → pop 返回

4. 通讯录 Tab 红点：
   - BlocBuilder<FriendCubit, FriendState> 读取 pendingCount
   - pendingCount > 0 时显示红点（复用消息 Tab 的 badge 样式）

5. initState 中加载好友列表：
   - context.read<FriendCubit>().loadFriends()

---

## 任务 8：编译验证 `⬜ 待处理`

### 8.1 flutter analyze `⬜`

```bash
cd client
flutter analyze
```

### 8.2 手动验证路径 `⬜`

1. 启动 App → 通讯录 Tab 显示好友列表（带字母索引栏）
2. 通讯录顶部三个入口：新的朋友 + 群通知（占位）+ 我的群聊（占位）
3. 点击"+"→ 搜索页 → 搜索"橘" → 看到橘橙 → 点击添加 → 输入留言 → 发送
4. 切换到用户 B → 通讯录红点 → 进入申请页（TabBar 双 Tab）→ 看到申请（含留言）→ 接受
5. 双方好友列表出现对方
6. 消息 Tab 出现新会话（打招呼消息）
7. 通讯录点击好友 → 进入 FriendDetailPage → 点击"发消息"→ 进入聊天页
8. FriendDetailPage 点击"删除好友"→ 好友消失
9. 好友申请页侧滑删除申请记录
10. "我的申请"Tab 显示发送的申请列表

---

## 任务 9：IndexedContactList + 拼音索引 `⬜ 待处理`

### 9.1 utils/pinyin_helper.dart `⬜`

文件：`client/modules/flash_im_friend/lib/src/utils/pinyin_helper.dart`（新建）

```dart
import 'package:lpinyin/lpinyin.dart';
```

工具方法：
- `String getFirstLetter(String name)` — 获取昵称的拼音首字母（大写），非字母归入 `#`
- `Map<String, List<Friend>> groupByLetter(List<Friend> friends)` — 按拼音首字母分组并排序

### 9.2 view/indexed_contact_list.dart `⬜`

文件：`client/modules/flash_im_friend/lib/src/view/indexed_contact_list.dart`（新建）

```dart
class IndexedContactList extends StatefulWidget
```

功能：
- 接收 `List<Friend>` 和 `onTap` 回调
- 使用 pinyin_helper 按拼音首字母分组
- 吸顶字母标题（SliverPersistentHeader 或 sticky_headers）
- 右侧字母索引栏（GestureDetector 滑动定位）
- 点击/滑动索引栏快速跳转到对应字母分组

---

## 任务 10：FriendDetailPage 好友详情页 `⬜ 待处理`

文件：`client/modules/flash_im_friend/lib/src/view/friend_detail_page.dart`（新建）

```dart
class FriendDetailPage extends StatelessWidget {
  final Friend friend;
```

微信风格详情页布局：
- 顶部大头像 + 昵称 + 签名（bio）
- 底部操作区：
  - "发消息"按钮 → ConversationRepository.createPrivate → push ChatPage
  - "删除好友"按钮（红色）→ 确认对话框 → cubit.deleteFriend() → pop 返回

---

## 任务 11：好友申请页 TabBar + 侧滑删除改造 `⬜ 待处理`

文件：`client/modules/flash_im_friend/lib/src/view/friend_request_page.dart`（修改）

在任务 5 基础上的增强：
- TabBar 双 Tab：好友申请（收到的）/ 我的申请（发送的）
- "我的申请"Tab 读取 FriendState.sentRequests，由 FriendCubit.loadSentRequests() 加载
- 两个 Tab 的列表项都包裹 Dismissible，侧滑触发 cubit.deleteRequest(id)
- 侧滑删除调用 DELETE /api/friends/requests/:id


---

## 任务 12：AddFriendPage 添加朋友主页 `⬜ 待处理`

文件：`client/modules/flash_im_friend/lib/src/view/add_friend_page.dart`（新建）

```dart
class AddFriendPage extends StatelessWidget
```

微信风格"添加朋友"主页布局：
- AppBar：标题"添加朋友"
- 顶部搜索入口：点击跳转 UserSearchPage（独立搜索页）
- 功能入口列表：
  - 扫一扫（占位，暂不实现）
  - 创建群聊（占位，暂不实现）
- 底部个人二维码区域：使用 qr_flutter 展示当前用户的二维码

导航变更：
- home_page.dart 通讯录"+"按钮改为跳转 AddFriendPage（不再直接跳 UserSearchPage）
- UserSearchPage 改为从 AddFriendPage 搜索入口跳转进入

---

## 任务 13：FlashSearchBar / FlashSearchInput 共享组件 `⬜ 待处理`

文件：`client/modules/flash_shared/lib/src/search_bar.dart`（新建或修改）

新增共享搜索组件到 flash_shared 模块：

- `FlashSearchBar` — 搜索栏容器组件（可点击跳转或内嵌输入框）
- `FlashSearchInput` — 搜索输入框组件（带搜索图标 + hint 文字 + 清除按钮）

供 AddFriendPage 和 UserSearchPage 复用。

---

## 任务 14：qr_flutter 依赖 + AddFriendPage 个人二维码 `⬜ 待处理`

### 14.1 pubspec.yaml 新增依赖 `⬜`

文件：`client/modules/flash_im_friend/pubspec.yaml`（修改）

```yaml
  qr_flutter: ^4.1.0
```

### 14.2 AddFriendPage 底部二维码 `⬜`

在 AddFriendPage 底部区域使用 `QrImageView` 展示当前用户的闪讯号二维码。

---

## 任务 15：FriendRequestPage AppBar 添加朋友按钮 + 搜索 hint 更新 + 导航调整 `⬜ 待处理`

### 15.1 FriendRequestPage AppBar 新增按钮 `⬜`

文件：`client/modules/flash_im_friend/lib/src/view/friend_request_page.dart`（修改）

- AppBar actions 新增"添加朋友"文字按钮
- 接收 `onAddFriendTap` 回调，点击跳转 AddFriendPage

### 15.2 搜索 hint 文字更新 `⬜`

文件：`client/modules/flash_im_friend/lib/src/view/user_search_page.dart`（修改）

- 搜索输入框 hint 文字改为"闪讯号 / 手机号 / 昵称"
- 对齐服务端三种匹配方式

### 15.3 home_page.dart 导航调整 `⬜`

文件：`client/lib/src/home/view/home_page.dart`（修改）

- 通讯录"+"按钮 onAddFriendTap 改为跳转 AddFriendPage（不再直接跳 UserSearchPage）


---

## 任务 16：UserProfilePage + SendRequestPage + 搜索流程 `✅ 已完成`

### 16.1 UserProfile 数据模型 `✅`

文件：`client/modules/flash_im_friend/lib/src/data/friend.dart`（修改）

新增 `UserProfile` 类（id/nickname/avatar/signature），用于资料页展示完整用户信息。

### 16.2 FriendRepository.getUserProfile + sendRequest `✅`

文件：`client/modules/flash_im_friend/lib/src/data/friend_repository.dart`（修改）

新增方法：
- `Future<UserProfile> getUserProfile(String userId)` → GET /api/users/:id
- `Future<void> sendRequest(String toUserId, {String? message})` → POST /api/friends/requests

### 16.3 UserProfilePage `✅`

文件：`client/modules/flash_im_friend/lib/src/view/user_profile_page.dart`（新建）

陌生人资料页：大头像 64px + 昵称 + 闪讯号 + 个性签名 + "添加到通讯录"蓝色文字按钮。点击按钮跳转 SendRequestPage。

### 16.4 SendRequestPage `✅`

文件：`client/modules/flash_im_friend/lib/src/view/send_request_page.dart`（新建）

申请表单页：打招呼内容输入框（最多 200 字）+ 蓝色"发送"按钮。发送成功后回调 `FriendCubit.loadSentRequests()` 刷新"我的申请"Tab，然后 pop 两层返回搜索页。

### 16.5 UserSearchPage 搜索结果跳转 `✅`

文件：`client/modules/flash_im_friend/lib/src/view/user_search_page.dart`（修改）

搜索结果点击流程：全屏 loading → GET /api/users/:id 获取完整资料 → push UserProfilePage。


---

## 任务 17：ScanPage 扫码添加好友 `⬜ 待处理`

### 17.1 新增 mobile_scanner 依赖 `⬜`

文件：`client/modules/flash_im_friend/pubspec.yaml`（修改）

```yaml
mobile_scanner: ^6.0.0
```

### 17.2 Android 摄像头权限 `⬜`

文件：`client/android/app/src/main/AndroidManifest.xml`（修改）

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### 17.3 ScanPage `⬜`

文件：`client/modules/flash_im_friend/lib/src/view/scan_page.dart`（新建）

```dart
class ScanPage extends StatefulWidget
```

功能：
- 全屏摄像头预览（MobileScanner widget）
- 扫到二维码后解析内容，匹配 `flashim://user/{id}` 格式
- 提取 userId → 全屏 loading → GET /api/users/:id → push UserProfilePage
- 非闪讯二维码提示"无法识别"
- AppBar 标题"扫一扫"

### 17.4 AddFriendPage 扫一扫入口 `⬜`

文件：`client/modules/flash_im_friend/lib/src/view/add_friend_page.dart`（修改）

"扫一扫"入口的 onTap 从空函数改为跳转 ScanPage。

### 17.5 平台适配 `⬜`

Windows 桌面端不支持摄像头，需要在 AddFriendPage 中判断平台：
- Android/iOS：显示"扫一扫"入口
- Windows/Linux/macOS：隐藏或置灰"扫一扫"入口
