# session — 客户端任务清单

基于 [design.md](./design.md) 设计，将 AuthCubit 迁移为 flash_session 独立 package。

全局约束：
- 状态管理使用 Cubit，不使用 Event 模式
- User 模型从主工程迁入 flash_session，其他模块统一从 `package:flash_session` 导入
- SessionRepository 内部管理本地缓存（SharedPreferences），外部不再直接读写会话数据
- 迁移完成后，旧的 AuthCubit / AuthState / legacy AuthRepository / StartupRepository 应被删除

---

## 执行顺序

1. ✅ 任务 1 — 创建 flash_session package 骨架（无依赖）
2. ✅ 任务 2 — User 模型迁入（无依赖）
3. ✅ 任务 3 — SessionState + SessionStatus（依赖任务 2）
4. ✅ 任务 4 — SessionRepository（依赖任务 2、3）
5. ✅ 任务 5 — SessionCubit（依赖任务 3、4）
6. ✅ 任务 6 — barrel file 导出（依赖任务 2-5）
7. ✅ 任务 7 — 主工程添加 flash_session 依赖（依赖任务 1）
8. ✅ 任务 8 — main.dart 组装层迁移（依赖任务 5-7）
9. ✅ 任务 9 — router.dart 简化（依赖任务 8）
10. ✅ 任务 10 — home_page.dart 迁移（依赖任务 8）
11. ✅ 任务 11 — profile_page.dart 迁移（依赖任务 8）
12. ✅ 任务 12 — set_password_page.dart 迁移（依赖任务 8）
13. ✅ 任务 13 — splash_page.dart 简化（依赖任务 8）
14. ✅ 任务 14 — 清理旧代码（依赖任务 8-13）
15. ✅ 任务 15 — 编译验证

---

## 任务 1：flash_session package 骨架 `✅ 已完成`

### 1.1 使用 flutter create 创建 package `⬜`

在 `client/modules/` 目录下执行：

```bash
flutter create --template=package flash_session
```

### 1.2 修改 pubspec.yaml 添加依赖 `⬜`

文件：`client/modules/flash_session/pubspec.yaml`（修改）

在 dependencies 中添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.0
  equatable: ^2.0.0
  dio: ^5.8.0+1
  shared_preferences: ^2.3.0
```

### 1.3 清理自动生成的模板文件 `⬜`

删除 `lib/flash_session.dart` 中的模板内容，后续任务 6 会重写 barrel file。

---

## 任务 2：User 模型迁入 `✅ 已完成`

文件：`client/modules/flash_session/lib/src/model/user.dart`（新建）

### 2.1 从主工程复制 User 模型 `⬜`

从 `client/lib/src/domain/model/user.dart` 复制，保持字段和 fromJson/toJson 不变：

```dart
class User {
  final int userId;
  final String phone;
  final String nickname;
  final String avatar;

  const User({...});
  factory User.fromJson(Map<String, dynamic> json) => ...;
  Map<String, dynamic> toJson() => ...;
}
```

---

## 任务 3：SessionState + SessionStatus `✅ 已完成`

文件：`client/modules/flash_session/lib/src/session_state.dart`（新建）

### 3.1 定义 SessionStatus 枚举 `⬜`

```dart
enum SessionStatus { unknown, active, ended }
```

### 3.2 定义 SessionState `⬜`

参考现有 AuthState 结构，替换命名：

```dart
class SessionState extends Equatable {
  final SessionStatus status;
  final String? token;
  final User? user;
  final bool hasPassword;

  // 命名构造函数：
  // SessionState.unknown()
  // SessionState.active({required token, user, hasPassword})
  // SessionState.ended()
}
```

---

## 任务 4：SessionRepository `✅ 已完成`

文件：`client/modules/flash_session/lib/src/session_repository.dart`（新建）

### 4.1 网络方法 `⬜`

```dart
class SessionRepository {
  final Dio _dio;

  SessionRepository({required Dio dio}) : _dio = dio;

  /// GET /user/profile — 获取当前用户资料
  Future<User> fetchProfile();
  // 1. _dio.get('/user/profile')
  // 2. User.fromJson(res.data)

  /// POST /auth/password — 设置/修改密码
  Future<void> setPassword(String newPassword);
  // 1. _dio.post('/auth/password', data: {'new_password': newPassword})
  // 2. 更新本地缓存 has_password = true
}
```

### 4.2 本地缓存方法 `⬜`

```dart
  /// 缓存会话数据
  Future<void> saveLocal({required String token, User? user, bool hasPassword = false});
  // SharedPreferences 写入：auth_token, user_info(json), has_password

  /// 读取本地缓存
  Future<SessionSnapshot?> loadLocal();
  // SharedPreferences 读取，返回 SessionSnapshot 或 null

  /// 清除缓存
  Future<void> clearLocal();
  // SharedPreferences 移除 auth_token, user_info, has_password
```

### 4.3 定义 SessionSnapshot `⬜`

```dart
class SessionSnapshot {
  final String token;
  final User? user;
  final bool hasPassword;
}
```

SessionSnapshot 是内部类型，不通过 barrel file 导出。

---

## 任务 5：SessionCubit `✅ 已完成`

文件：`client/modules/flash_session/lib/src/session_cubit.dart`（新建）

### 5.1 构造函数和 token getter `⬜`

```dart
class SessionCubit extends Cubit<SessionState> {
  final SessionRepository _repo;

  SessionCubit({required SessionRepository repo})
      : _repo = repo, super(const SessionState.unknown());

  String? get token => state.token;
}
```

### 5.2 restore() `⬜`

```dart
  Future<void> restore() async {
    // 1. 调 _repo.loadLocal()
    // 2. snapshot != null && snapshot.token 存在 → emit active
    // 3. 否则 → emit ended
  }
```

### 5.3 activate() `⬜`

```dart
  Future<void> activate({required String token, bool hasPassword = false}) async {
    // 1. emit active(token, hasPassword: hasPassword) — user 暂为 null
    // 2. 调 _repo.fetchProfile() 获取 user
    // 3. 调 _repo.saveLocal(token, user, hasPassword) 缓存
    // 4. emit active(token, user, hasPassword)
    // 注意：fetchProfile 失败不应阻塞，user 保持 null 即可
  }
```

### 5.4 setPassword() `⬜`

```dart
  Future<void> setPassword(String newPassword) async {
    // 1. 调 _repo.setPassword(newPassword)
    // 2. emit active(token, user, hasPassword: true)
  }
```

### 5.5 deactivate() `⬜`

```dart
  Future<void> deactivate() async {
    // 1. 调 _repo.clearLocal()
    // 2. emit ended
  }
```

---

## 任务 6：barrel file `✅ 已完成`

文件：`client/modules/flash_session/lib/flash_session.dart`（新建）

### 6.1 导出公开 API `⬜`

```dart
library;

export 'src/session_cubit.dart' show SessionCubit;
export 'src/session_repository.dart' show SessionRepository;
export 'src/session_state.dart' show SessionState, SessionStatus;
export 'src/model/user.dart' show User;
```

---

## 任务 7：主工程添加依赖 `✅ 已完成`

文件：`client/pubspec.yaml`（修改）

### 7.1 添加 flash_session path 依赖 `⬜`

在 dependencies 中添加：

```yaml
  flash_session:
    path: modules/flash_session
```

然后执行 `flutter pub get`。

---

## 任务 8：main.dart 组装层迁移 `✅ 已完成`

文件：`client/lib/main.dart`（修改）

### 8.1 替换 import 和实例化 `⬜`

变更：
- 删除 `import 'src/auth/logic/auth/auth_cubit.dart'`
- 删除 `import 'src/auth/data/repository/auth_repository.dart' as legacy`
- 删除 `import 'src/starter/data/repository/startup_repository.dart'`
- 新增 `import 'package:flash_session/flash_session.dart'`

### 8.2 重写依赖组装 `⬜`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 创建 SessionCubit（需要先创建 SessionRepository，但 SessionRepository 需要 dio）
  // 2. 创建 HttpClient，tokenProvider 从 sessionCubit.token 读取
  // 3. 创建 SessionRepository(dio: httpClient.dio)
  // 4. 创建 SessionCubit(repo: sessionRepository)
  // 注意：HttpClient 需要 tokenProvider，而 token 来自 SessionCubit
  //       但 SessionCubit 需要 SessionRepository 需要 dio
  //       解决：先创建 HttpClient（tokenProvider 用闭包延迟读取），再创建 repo 和 cubit

  // 5. 创建 AuthRepository(dio: httpClient.dio) — flash_auth 的
  // 6. 删除 legacyAuthRepository — 不再需要
  // 7. 删除 startupRepository — 不再需要
}
```

### 8.3 重写路由创建和回调 `⬜`

```dart
  router = createRouter(
    authRepository: authRepository,
    sessionCubit: sessionCubit,
    onLoginSuccess: (loginResult) async {
      await sessionCubit.activate(
        token: loginResult.token,
        hasPassword: loginResult.hasPassword,
      );
      router.go('/home');
    },
  );
```

### 8.4 替换 BlocProvider `⬜`

```dart
  // BlocProvider<AuthCubit> → BlocProvider<SessionCubit>
  BlocProvider.value(
    value: sessionCubit,
    child: FlashApp(router: router),
  )
```

---

## 任务 9：router.dart 简化 `✅ 已完成`

文件：`client/lib/src/application/router.dart`（修改）

### 9.1 移除 StartupRepository 和 legacy 相关参数 `⬜`

```dart
GoRouter createRouter({
  required AuthRepository authRepository,
  required SessionCubit sessionCubit,
  required OnLoginSuccess onLoginSuccess,
}) {
  // '/' → SplashPage 改为直接调 sessionCubit.restore() 的简单启动页
  // '/login' → LoginPage（不变）
  // '/home' → HomePage（不再传 authRepository，改传 sessionCubit）
}
```

### 9.2 SplashPage 路由调整 `⬜`

SplashPage 不再需要 StartupRepository 和 onStartupComplete 回调。
改为接收 SessionCubit，内部调 restore() 后根据状态跳转。

---

## 任务 10：home_page.dart 迁移 `✅ 已完成`

文件：`client/lib/src/home/view/home_page.dart`（修改）

### 10.1 替换 import `⬜`

- 删除 `import '../../auth/logic/auth/auth_cubit.dart'`
- 删除 `import '../../auth/logic/auth/auth_state.dart'`
- 删除 `import '../../auth/data/repository/auth_repository.dart'`
- 新增 `import 'package:flash_session/flash_session.dart'`

### 10.2 替换构造函数参数 `⬜`

```dart
// 删除 final AuthRepository authRepository;
// HomePage 不再需要 authRepository 参数
// SetPasswordPage 也不再需要 authRepository，改用 SessionCubit
```

### 10.3 替换状态读取 `⬜`

```dart
// context.read<AuthCubit>() → context.read<SessionCubit>()
// AuthStatus.authenticated → SessionStatus.active
// state.hasPassword → state.hasPassword（不变）
```

---

## 任务 11：profile_page.dart 迁移 `✅ 已完成`

文件：`client/lib/src/home/profile/profile_page.dart`（修改）

### 11.1 替换 import `⬜`

- 删除 AuthCubit / AuthState / AuthRepository 的 import
- 新增 `import 'package:flash_session/flash_session.dart'`

### 11.2 替换 BlocBuilder `⬜`

```dart
// BlocBuilder<AuthCubit, AuthState> → BlocBuilder<SessionCubit, SessionState>
```

### 11.3 替换退出登录逻辑 `⬜`

```dart
// 旧：await authRepository.logout(); context.read<AuthCubit>().logout();
// 新：await context.read<SessionCubit>().deactivate();
//     context.go('/login');
```

### 11.4 移除 authRepository 构造参数 `⬜`

ProfilePage 不再需要 AuthRepository 参数。设置密码通过 SessionCubit 完成。

---

## 任务 12：set_password_page.dart 迁移 `✅ 已完成`

文件：`client/lib/src/home/profile/set_password_page.dart`（修改）

### 12.1 替换 import `⬜`

- 删除 AuthCubit / AuthRepository 的 import
- 新增 `import 'package:flash_session/flash_session.dart'`

### 12.2 移除 authRepository 参数 `⬜`

SetPasswordPage 不再接收 AuthRepository。密码设置通过 SessionCubit.setPassword() 完成。

### 12.3 替换 _submit 逻辑 `⬜`

```dart
// 旧：await widget.authRepository.setPassword(...);
//     context.read<AuthCubit>().onPasswordSet();
// 新：await context.read<SessionCubit>().setPassword(...);
```

### 12.4 ActionButton import 路径 `⬜`

`action_button.dart` 目前在 `auth/view/components/` 下。
迁移后需要确认 import 路径。如果 flash_auth 不导出 ActionButton，
则需要将 ActionButton 复制到本地或 flash_session 中。

暂时方案：直接在 set_password_page.dart 中内联一个简单按钮，
或从 flash_auth 的 src 中复制 ActionButton 到主工程的 shared 目录。

---

## 任务 13：splash_page.dart 简化 `✅ 已完成`

文件：`client/lib/src/starter/view/splash_page.dart`（修改）

### 13.1 移除 StartupRepository 依赖 `⬜`

```dart
class SplashPage extends StatefulWidget {
  final SessionCubit sessionCubit;
  // 删除 startupRepository 和 onStartupComplete
}
```

### 13.2 重写初始化逻辑 `⬜`

```dart
Future<void> _startInitialization() async {
  // 1. await widget.sessionCubit.restore()
  // 2. 延迟 1.5 秒（保持 splash 动画）
  // 3. 根据 sessionCubit.state.status 跳转：
  //    active → context.go('/home')
  //    ended → context.go('/login')
}
```

---

## 任务 14：清理旧代码 `✅ 已完成`

### 14.1 删除旧文件 `⬜`

- `client/lib/src/auth/logic/auth/auth_cubit.dart`
- `client/lib/src/auth/logic/auth/auth_state.dart`
- `client/lib/src/auth/data/repository/auth_repository.dart`（legacy）
- `client/lib/src/auth/data/model/login_result.dart`（如果存在且不再使用）
- `client/lib/src/domain/model/user.dart`（已迁入 flash_session）
- `client/lib/src/starter/data/repository/startup_repository.dart`（已被 SessionRepository 取代）
- `client/lib/src/starter/data/model/startup_result.dart`（不再需要）

### 14.2 确认无残留引用 `⬜`

全局搜索以下关键词，确保无残留：
- `AuthCubit`
- `AuthState`
- `AuthStatus`
- `legacy.AuthRepository`
- `StartupRepository`
- `StartupResult`
- `applyStartupSnapshot`
- `domain/model/user.dart`

---

## 任务 15：编译验证 `✅ 已完成`

### 15.1 flutter analyze `⬜`

在 `client/` 目录执行 `flutter analyze`，确保零错误。

### 15.2 验证路径 `⬜`

手动验证以下流程：
1. 冷启动 → splash → 无缓存 → 跳转 /login
2. 登录 → activate → 拉取 profile → 跳转 /home
3. profile 页面显示用户信息
4. 设置密码 → hasPassword 更新
5. 退出登录 → deactivate → 跳转 /login
6. 再次冷启动 → splash → 无缓存（已清除）→ 跳转 /login
