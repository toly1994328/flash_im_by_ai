# Starter 模块 — Client 任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。
前端项目当前为空白状态，本次从零搭建启动流程。
启动流程使用 Stream（broadcast）驱动，路由使用 go_router 管理。
启动完成后通过 `onStartupComplete` 回调将结果传出，组装层（main.dart）拆包交给 AuthCubit。
starter 和 auth 模块彼此完全解耦。

---

## 执行顺序

1. ✅ 任务 1 — 依赖安装（无依赖）
   - ✅ 1.1 pubspec.yaml 添加 go_router
2. ✅ 任务 2 — 启动事件 + StartupResult 模型（依赖任务 1）
   - ✅ 2.1 启动事件类型定义
   - ✅ 2.2 StartupResult 模型
3. ✅ 任务 3 — StartupRepository（依赖任务 2，直接读取 SharedPreferences）
   - ✅ 3.1 StreamController.broadcast() 事件流
   - ✅ 3.2 initialize() 从本地缓存读取
4. ✅ 任务 4 — SplashPage 闪屏页（依赖任务 3）
   - ✅ 4.1 闪屏 UI（logo.png + Flash IM 文字）
   - ✅ 4.2 Stream 监听 + onStartupComplete 回调 + go_router 跳转
   - ✅ 4.3 失败重试
5. ✅ 任务 5 — GoRouter 路由配置（依赖任务 4）
   - ✅ 5.1 路由表定义，默认路由为闪屏页
6. ✅ 任务 6 — app.dart 接入路由（依赖任务 5）
   - ✅ 6.1 MaterialApp.router 接入 GoRouter
7. ✅ 任务 7 — AuthCubit 全局认证状态（依赖任务 2）
   - ✅ 7.1 AuthState 状态定义（unknown / authenticated / unauthenticated）
   - ✅ 7.2 AuthCubit 实现（applyStartupSnapshot / login / logout）
   - ✅ 7.3 main.dart 通过 BlocProvider 全局提供 AuthCubit
8. ⬜ 任务 8 — 编译验证 + 测试路径（依赖全部）
   - ✅ 8.1 编译通过
   - ⬜ 8.2 端到端测试

---

## 任务 1：依赖安装 `✅ 已完成`

文件：`client/pubspec.yaml`（修改）

### 1.1 添加 go_router `✅`

```yaml
dependencies:
  go_router: ^17.1.0
```

执行 `flutter pub get`。

---

## 任务 2：startup_result.dart — 启动事件 + 结果模型 `✅ 已完成`

文件：`client/lib/src/starter/data/model/startup_result.dart`（新建）

### 2.1 启动事件类型 `✅`

```dart
sealed class StartupEvent {}
class StartupLoading extends StartupEvent {}
class StartupReady extends StartupEvent {
  final StartupResult result;
}
class StartupFailed extends StartupEvent {
  final String message;
}
```

### 2.2 StartupResult 模型 `✅`

```dart
class StartupResult {
  final String? token;
  final User? user;
  final bool hasPassword;
  bool get authenticated => token != null;
}
```

---

## 任务 3：startup_repository.dart — 启动仓库 `✅ 已完成`

文件：`client/lib/src/starter/data/repository/startup_repository.dart`（新建）

### 3.1 StreamController.broadcast() 事件流 `✅`

```dart
class StartupRepository {
  final _controller = StreamController<StartupEvent>.broadcast();

  Stream<StartupEvent> get stream => _controller.stream;
  void dispose() => _controller.close();
}
```

### 3.2 initialize() 从本地缓存读取 `✅`

```dart
Future<void> initialize()
// 1. _controller.add(StartupLoading())
// 2. try: SharedPreferences.getInstance()
// 3. 读取 token = prefs.getString('auth_token')
// 4. token == null → emit StartupReady(token: null)
// 5. 读取 userJson = prefs.getString('user_info')，jsonDecode → User.fromJson
// 6. 读取 hasPassword = prefs.getBool('has_password')
// 7. emit StartupReady(token, user, hasPassword)
// 8. catch → emit StartupFailed(error.toString())
```

---

## 任务 4：splash_page.dart — 闪屏页 `✅ 已完成`

文件：`client/lib/src/starter/view/splash_page.dart`（新建）

### 4.1 闪屏 UI `✅`

- 白色背景，居中显示 `Image.asset('assets/images/logo.png')` + "Flash IM" 文字
- Logo 和文字纵向排列，间距适中

### 4.2 Stream 监听 + onStartupComplete 回调 + go_router 跳转 `✅`

- `initState` 中触发 `StartupRepository.initialize()`
- `Future.wait` 同时等待 Stream 首个非 Loading 事件和 1.5 秒延迟
- `StartupReady` → `widget.onStartupComplete(result)` 通过回调传出结果
- `result.authenticated`（token != null）→ `context.go('/home')`
- `!result.authenticated`（token == null）→ `context.go('/login')`

### 4.3 失败重试 `✅`

- `StartupFailed` → Logo 下方显示错误提示 + 重试按钮
- 点击重试 → 重新调用 `initialize()`

---

## 任务 5：router.dart — GoRouter 路由配置 `✅ 已完成`

文件：`client/lib/src/router.dart`（新建）

### 5.1 路由表定义 `✅`

```dart
GoRouter createRouter({
  required StartupRepository startupRepository,
  required ValueChanged<StartupResult> onStartupComplete,
}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => SplashPage(
        startupRepository: startupRepository,
        onStartupComplete: onStartupComplete,
      )),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
    ],
  );
}
```

---

## 任务 6：app.dart — 接入路由 `✅ 已完成`

文件：`client/lib/src/app.dart`（新建）

### 6.1 MaterialApp.router 接入 GoRouter `✅`

```dart
class FlashApp extends StatelessWidget {
  final GoRouter router;
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flash IM',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
```

---

## 任务 7：AuthCubit — 全局认证状态 `✅ 已完成`

### 7.1 AuthState 状态定义 `✅`

文件：`client/lib/src/auth/cubit/auth_state.dart`（新建）

```dart
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? token;
  final User? user;
  final bool hasPassword;
}
```

- `unknown` — 初始状态，启动尚未完成
- `authenticated` — 已认证，携带 token、user、hasPassword
- `unauthenticated` — 未认证

### 7.2 AuthCubit 实现 `✅`

文件：`client/lib/src/auth/cubit/auth_cubit.dart`（新建）

```dart
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState.unknown());

  void applyStartupSnapshot({     // 接收原始字段，不依赖 StartupResult
    required String? token,
    User? user,
    bool hasPassword = false,
  });
  void login({token, user, hasPassword});
  void logout();
}
```

### 7.3 main.dart 全局提供 AuthCubit `✅`

文件：`client/lib/main.dart`（修改）

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final startupRepository = StartupRepository();
  final authCubit = AuthCubit();
  final router = createRouter(
    startupRepository: startupRepository,
    onStartupComplete: (result) => authCubit.applyStartupSnapshot(
      token: result.token,
      user: result.user,
      hasPassword: result.hasPassword,
    ),
  );
  runApp(
    BlocProvider.value(
      value: authCubit,
      child: FlashApp(router: router),
    ),
  );
}
```

---

## 任务 8：编译验证 + 测试路径 `⬜ 待处理`

### 8.1 编译通过 `✅`

- 零诊断错误

### 8.2 端到端测试 `⬜`

1. 启动后进入闪屏页，显示 logo.png + "Flash IM"
2. 无 Token → 闪屏结束后跳转 `/login`
3. 有有效 Token → 闪屏结束后跳转 `/home`
4. 退出登录 → 回到 `/login`（不经过闪屏）
5. 重启应用 → 再次经过闪屏
