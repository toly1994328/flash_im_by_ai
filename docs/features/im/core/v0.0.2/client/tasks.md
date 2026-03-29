# IM Core v0.0.2 — 客户端任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。
三层架构：data / logic / view，与其他模块保持一致。
使用 flutter create --template=package 创建模块。
核心流程参考 `docs/ref/flash_im-main/app/packages/im_conversation/`。

---

## 执行顺序

1. ✅ 任务 1 — 创建 flash_im_conversation 模块骨架（无依赖）
   - ✅ 1.1 flutter create
   - ✅ 1.2 添加依赖
   - ✅ 1.3 三层目录结构
2. ✅ 任务 2 — Conversation 数据模型（依赖任务 1）
3. ✅ 任务 3 — ConversationRepository（依赖任务 2）
4. ✅ 任务 4 — ConversationListCubit + State（依赖任务 3）
5. ✅ 任务 5 — ConversationTile 组件（依赖任务 2）
6. ✅ 任务 6 — ConversationListPage 页面（依赖任务 4、5）
7. ✅ 任务 7 — barrel 导出（依赖任务 2~6）
8. ✅ 任务 8 — 主工程集成（依赖任务 7）
   - ✅ 8.1 pubspec.yaml 注册模块
   - ✅ 8.2 main.dart 注入 Repository
   - ✅ 8.3 HomePage 消息 Tab 替换
9. ✅ 任务 9 — 编译验证 + 功能验证
10. ✅ 任务 10 — 单元测试 + 集成测试

---

## 任务 1：模块骨架 `✅`

### 1.1 flutter create `✅`

如果 `client/modules/flash_im_conversation` 已存在，先删除。

```powershell
cd client/modules
flutter create --template=package --project-name=flash_im_conversation flash_im_conversation
```

### 1.2 添加依赖 `✅`

文件：`client/modules/flash_im_conversation/pubspec.yaml`（修改）

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.8.0+1
  flutter_bloc: ^8.1.6
  equatable: ^2.0.7
  flash_session:
    path: ../flash_session
```

### 1.3 三层目录结构 `✅`

```
lib/src/
├── data/
│   ├── conversation.dart
│   └── conversation_repository.dart
├── logic/
│   ├── conversation_list_cubit.dart
│   └── conversation_list_state.dart
└── view/
    ├── conversation_list_page.dart
    └── conversation_tile.dart
```

---

## 任务 2：conversation.dart — 数据模型 `✅`

文件：`client/modules/flash_im_conversation/lib/src/data/conversation.dart`（新建）

```dart
class Conversation {
  final String id;
  final int type;           // 0:单聊 1:群聊
  final String? name;       // 群聊名称
  final String? peerUserId; // 单聊对方 ID
  final String? peerNickname;
  final String? peerAvatar;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final DateTime createdAt;

  // fromJson 工厂方法
  // 字段映射：peer_user_id, peer_nickname, peer_avatar, last_message_at,
  //          last_message_preview, unread_count, is_pinned, is_muted, created_at
}
```

---

## 任务 3：conversation_repository.dart — API 调用 `✅`

文件：`client/modules/flash_im_conversation/lib/src/data/conversation_repository.dart`（新建）

```dart
class ConversationRepository {
  final Dio _dio;

  ConversationRepository({required Dio dio}) : _dio = dio;

  /// 获取会话列表
  Future<List<Conversation>> getList() async
  // GET /conversations → List<Conversation>.fromJson

  /// 创建私聊会话
  Future<Conversation> createPrivate(int peerUserId) async
  // POST /conversations { peer_user_id } → Conversation.fromJson

  /// 删除会话
  Future<void> delete(String conversationId) async
  // DELETE /conversations/:id
}
```

---

## 任务 4：ConversationListCubit + State `✅`

### 4.1 conversation_list_state.dart `✅`

文件：`client/modules/flash_im_conversation/lib/src/logic/conversation_list_state.dart`（新建）

```dart
sealed class ConversationListState extends Equatable { ... }
class ConversationListInitial extends ConversationListState { ... }
class ConversationListLoading extends ConversationListState { ... }
class ConversationListLoaded extends ConversationListState {
  final List<Conversation> conversations;
}
class ConversationListError extends ConversationListState {
  final String message;
}
```

### 4.2 conversation_list_cubit.dart `✅`

文件：`client/modules/flash_im_conversation/lib/src/logic/conversation_list_cubit.dart`（新建）

```dart
class ConversationListCubit extends Cubit<ConversationListState> {
  final ConversationRepository _repository;

  ConversationListCubit(this._repository) : super(const ConversationListInitial());

  /// 加载会话列表
  Future<void> loadConversations() async
  // 1. emit Loading
  // 2. repo.getList()
  // 3. emit Loaded(conversations) 或 emit Error

  /// 删除会话
  Future<void> deleteConversation(String id) async
  // 1. repo.delete(id)
  // 2. 从当前列表中移除
  // 3. emit Loaded(更新后的列表)
}
```

---

## 任务 5：conversation_tile.dart — 单条会话组件 `✅`

文件：`client/modules/flash_im_conversation/lib/src/view/conversation_tile.dart`（新建）

参考项目的会话列表项样式：

```dart
class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  // 布局：
  // Row [
  //   UserAvatar（对方头像，圆角矩形）
  //   SizedBox(width: 12)
  //   Expanded Column [
  //     Row [ 昵称(Expanded)  时间(右对齐，灰色小字) ]
  //     SizedBox(height: 4)
  //     Row [ 预览文字(Expanded，灰色，单行截断)  未读数(红色圆点，如果>0) ]
  //   ]
  // ]
  // 整体 padding: 12, 底部分隔线
}
```

头像使用 flash_session 的 UserAvatar 组件（通过 peerUserId 构建临时 User 对象，或直接用 peerAvatar URL）。

---

## 任务 6：conversation_list_page.dart — 列表页面 `✅`

文件：`client/modules/flash_im_conversation/lib/src/view/conversation_list_page.dart`（新建）

```dart
class ConversationListPage extends StatelessWidget {
  // BlocBuilder<ConversationListCubit, ConversationListState>
  // Loading → CircularProgressIndicator
  // Error → 错误提示 + 重试按钮
  // Loaded(empty) → 空状态提示
  // Loaded(conversations) → ListView.builder + ConversationTile
  //
  // 下拉刷新：RefreshIndicator → cubit.loadConversations()
}
```

---

## 任务 7：barrel 导出 `✅`

文件：`client/modules/flash_im_conversation/lib/flash_im_conversation.dart`（修改）

```dart
// data
export 'src/data/conversation.dart';
export 'src/data/conversation_repository.dart';

// logic
export 'src/logic/conversation_list_cubit.dart';
export 'src/logic/conversation_list_state.dart';

// view
export 'src/view/conversation_list_page.dart';
export 'src/view/conversation_tile.dart';
```

---

## 任务 8：主工程集成 `✅`

### 8.1 pubspec.yaml `✅`

文件：`client/pubspec.yaml`（修改）

```yaml
  flash_im_conversation:
    path: modules/flash_im_conversation
```

### 8.2 main.dart 注入 `✅`

文件：`client/lib/main.dart`（修改）

```dart
import 'package:flash_im_conversation/flash_im_conversation.dart';

// 创建 repository
final conversationRepo = ConversationRepository(dio: httpClient.dio);

// 通过 RepositoryProvider 传递
RepositoryProvider.value(value: conversationRepo),
```

### 8.3 HomePage 消息 Tab 替换 `✅`

文件：`client/lib/src/home/view/home_page.dart`（修改）

将 `_buildMessageTab()` 中的 body 从"暂无消息"占位替换为：

```dart
body: BlocProvider(
  create: (_) => ConversationListCubit(context.read<ConversationRepository>())
    ..loadConversations(),
  child: const ConversationListPage(),
),
```

保留现有的 AppBar（用户头像 + 昵称 + 连接状态）。

---

## 任务 9：编译验证 + 功能验证 `✅`

### 9.1 编译 `✅`

```powershell
cd client
flutter pub get
flutter analyze
```

### 9.2 功能验证 `✅`

1. 重置数据库（执行种子数据）
2. 启动后端
3. 启动客户端
4. 用朱红（13800010001，密码 111111）登录
5. 消息 Tab 显示 51 条会话，每条显示对方头像、昵称
6. 有预览文字的会话显示最后消息和时间
7. 下拉刷新正常工作

---

## 任务 10：单元测试 + 集成测试 `✅`

### 10.1 测试依赖 `✅`

文件：`client/modules/flash_im_conversation/pubspec.yaml`（修改）

新增 dev_dependencies：
```yaml
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
```

### 10.2 数据模型单元测试 `✅`

文件：`client/modules/flash_im_conversation/test/conversation_test.dart`（新建）

测试用例：
- fromJson 解析完整 JSON
- 缺省字段使用默认值
- displayName 单聊用对方昵称
- displayName 群聊用群名
- displayName 无名称时回退

### 10.3 Cubit 逻辑单元测试 `✅`

文件：`client/modules/flash_im_conversation/test/conversation_list_cubit_test.dart`（新建）

使用 MockConversationRepository 测试：
- loadConversations 成功（不足一页 → hasMore=false）
- loadConversations 成功（刚好一页 → hasMore=true）
- loadConversations 失败 → Error 状态
- loadMore 追加数据，hasMore 正确更新
- hasMore=false 时不再请求
- loadMore 失败不影响已有数据
- deleteConversation 删除后列表减少

### 10.4 测试登录脚本 `✅`

文件：`client/test/login_for_test.dart`（新建）

纯 dart:io 实现，无外部依赖：
- 用朱红账号密码登录
- 将 BASE_URL、TOKEN、USER_ID、PHONE 写入 `client/test/.env`
- Token 有效期 7 天

### 10.5 共享测试工具类 `✅`

文件：`client/test/test_env.dart`（新建）

- 从 `test/.env` 或 `../../test/.env` 自动查找 .env 文件
- 提供 `TestEnv.load()` 和 `createDio()` 方法
- 各模块集成测试可复用

### 10.6 集成测试（真实网络请求） `✅`

文件：`client/modules/flash_im_conversation/test/conversation_api_test.dart`（新建）

直接使用 ConversationRepository 发真实请求：
- 获取第一页（20 条）
- 分页加载全部（51 条，3 页）
- 超出范围返回空列表
- 创建会话幂等（重复创建返回相同 ID）
- 删除会话后列表减少

运行方式：
```powershell
# 生成 token
cd client
dart test/login_for_test.dart

# 运行集成测试
cd modules/flash_im_conversation
flutter test test/conversation_api_test.dart
```
