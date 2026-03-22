# Auth 模块 — Client 任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。
starter 模块和 AuthCubit 骨架已完成，本次在此基础上实现完整认证流程。
登录页 UI 风格参考游乐场 `playground/auth/view/login_page.dart`。
"我的"页面参考游乐场 `playground/auth/view/profile_page.dart`。

---

## 执行顺序

1. ✅ 任务 1 — config.dart 全局配置（无依赖）
   - ✅ 1.1 AppConfig 类
2. ✅ 任务 2 — Dio 单例 + Token 拦截器（依赖任务 1）
   - ✅ 2.1 Dio 单例封装
   - ✅ 2.2 请求拦截器注入 Token
   - ✅ 2.3 响应拦截器处理 401
3. ✅ 任务 3 — LoginResult 数据模型（无依赖）
   - ✅ 3.1 LoginResult 模型
4. ✅ 任务 4 — AuthRepository 认证仓库（依赖任务 2、3）
   - ✅ 4.1 Token 管理（内存 + SharedPreferences）
   - ✅ 4.2 用户信息缓存（写入 user_info JSON + has_password）
   - ✅ 4.3 API 方法（sendSms / login / getProfile / setPassword / logout）
5. ✅ 任务 5 — 登录策略对象 + LoginMixin（依赖任务 4）
   - ✅ 5.1 SmsLoginStrategy（验证码登录策略）
   - ✅ 5.2 PasswordLoginStrategy（密码登录策略）
   - ✅ 5.3 LoginMixin（共享状态 + 登录调度）
6. ✅ 任务 6 — 登录页 UI 重写（依赖任务 5）
   - ✅ 6.1 视图组件拆分（components/）
   - ✅ 6.2 验证码模式 UI
   - ✅ 6.3 密码模式 UI（账号支持手机号/用户名/邮箱）+ 切换链接
   - ✅ 6.4 登录成功调用 AuthCubit.login + 跳转
7. ✅ 任务 7 — AuthCubit 扩展（依赖任务 4）
   - ✅ 7.1 新增 onPasswordSet() 方法
8. ✅ 任务 8 — 三 Tab 主页重写（无依赖）
   - ✅ 8.1 BottomNavigationBar 三 Tab 结构
9. ✅ 任务 9 — "我的"页面 + 密码设置页（依赖任务 4、7）
   - ✅ 9.1 用户信息展示（微信风格列表布局）
   - ✅ 9.2 设置/修改密码入口 → 独立页面 SetPasswordPage
   - ✅ 9.3 退出登录
10. ✅ 任务 10 — 密码设置引导弹窗（依赖任务 9）
    - ✅ 10.1 首次进入 HomePage 且未设密码时弹出引导
11. ✅ 任务 11 — main.dart + router.dart 组装更新（依赖全部）
    - ✅ 11.1 main.dart 创建 AuthRepository，注入各模块
    - ✅ 11.2 router.dart 更新路由（传递依赖）
12. ⬜ 任务 12 — 编译验证 + 测试路径（依赖全部）
    - ✅ 12.1 编译通过
    - ⬜ 12.2 端到端测试

---

## 任务 1：config.dart — 全局配置 `⬜ 待处理`

文件：`client/lib/src/config.dart`（新建）

### 1.1 AppConfig 类 `⬜`

```dart
class AppConfig {
  static String host = '192.168.1.75';
  static int port = 9600;
  static String get baseUrl => 'http://$host:$port';
}
```

---

## 任务 2：http_client.dart — Dio 单例 + Token 拦截器 `⬜ 待处理`

文件：`client/lib/src/network/http_client.dart`（新建）

### 2.1 Dio 单例封装 `⬜`

```dart
class HttpClient {
  late final Dio dio;
  // baseUrl 从 AppConfig 读取
  // connectTimeout: 10s, receiveTimeout: 10s
}
```

### 2.2 请求拦截器注入 Token `⬜`

```dart
// onRequest: 从 tokenProvider 回调获取 token
// token != null → headers['Authorization'] = 'Bearer $token'
```

- `tokenProvider` 是 `String? Function()` 回调，由外部注入，不直接依赖 AuthRepository

### 2.3 响应拦截器处理 401 `⬜`

```dart
// onError: statusCode == 401 → 调用 onUnauthorized 回调
```

- `onUnauthorized` 是 `VoidCallback`，由外部注入

---

## 任务 3：login_result.dart — 数据模型 `⬜ 待处理`

文件：`client/lib/src/auth/data/model/login_result.dart`（新建）

### 3.1 LoginResult 模型 `⬜`

```dart
class LoginResult {
  final String token;
  final int userId;
  final bool hasPassword;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token'] as String,
      userId: json['user_id'] as int,
      hasPassword: json['has_password'] as bool,
    );
  }
}
```

---

## 任务 4：auth_repository.dart — 认证仓库 `⬜ 待处理`

文件：`client/lib/src/auth/data/repository/auth_repository.dart`（新建）

### 4.1 Token 管理 `⬜`

```dart
class AuthRepository {
  final Dio _dio;
  String? _token;

  String? get token => _token;

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _clearAll() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_info');
    await prefs.remove('has_password');
  }
}
```

### 4.2 用户信息缓存 `⬜`

```dart
Future<void> _cacheUserInfo(User user, bool hasPassword) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_info', jsonEncode(user.toJson()));
  await prefs.setBool('has_password', hasPassword);
}
```

### 4.3 API 方法 `⬜`

```dart
Future<String> sendSms(String phone);
// POST /auth/sms → 返回 code

Future<({LoginResult loginResult, User user})> login(String phone, String credential, String type);
// 1. POST /auth/login → LoginResult
// 2. _saveToken(loginResult.token)
// 3. GET /user/profile → User
// 4. _cacheUserInfo(user, loginResult.hasPassword)
// 5. 返回 (loginResult, user)

Future<void> setPassword(String newPassword);
// POST /auth/password { new_password }

Future<void> logout();
// _clearAll()
```

---

## 任务 5：登录策略对象 + LoginMixin `⬜ 待处理`

文件：`client/lib/src/auth/logic/login/strategy/login_strategy.dart`（新建）
文件：`client/lib/src/auth/logic/login/strategy/sms_login_strategy.dart`（新建）
文件：`client/lib/src/auth/logic/login/strategy/password_login_strategy.dart`（新建）
文件：`client/lib/src/auth/logic/login/login_mixin.dart`（新建）

不使用状态管理框架，采用 Mixin + 策略对象模式。策略对象继承自抽象基类 `LoginStrategy`。

### 5.0 LoginStrategy 抽象基类 `✅`

```dart
abstract class LoginStrategy {
  bool get isValid;
  Future<LoginResultData> login(AuthRepository repo);
  void dispose();
}
```

- 只约束共性：能校验、能登录、能销毁
- 不强制 sendSms 等特有能力
- `LoginResultData` 为统一返回类型 `({LoginResult loginResult, User user})`

### 5.1 SmsLoginStrategy `✅`

```dart
class SmsLoginStrategy extends LoginStrategy {
  final phoneCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  int countdown = 0;

  bool get isPhoneValid => phone.length == 11 && phone.startsWith('1');
  bool get isValid => isPhoneValid && credential.isNotEmpty;
  bool get canSendSms => countdown <= 0;

  Future<LoginResultData> login(AuthRepository repo);  // repo.login(phone, credential, 'sms')
  Future<void> sendSms();  // 调用 AuthRepository.sendSms
  void dispose();
}
```

### 5.2 PasswordLoginStrategy `✅`

```dart
class PasswordLoginStrategy extends LoginStrategy {
  final accountCtrl = TextEditingController();  // 手机号/用户名/邮箱
  final passwordCtrl = TextEditingController();

  bool get isValid => phone.isNotEmpty && credential.isNotEmpty;
  Future<LoginResultData> login(AuthRepository repo);  // repo.login(phone, credential, 'password')
  void dispose();
}
```

### 5.3 LoginMixin `✅`

```dart
mixin LoginMixin on State<LoginPage> {
  late final SmsLoginStrategy smsStrategy;
  late final PasswordLoginStrategy passwordStrategy;
  LoginMode mode = LoginMode.sms;
  bool agreed = false;
  bool isLoading = false;

  LoginStrategy get currentStrategy;  // 按 mode 返回对应策略
  bool get canLogin => agreed && !isLoading && currentStrategy.isValid;

  void toggleMode();   // 切换 mode，各策略状态保留
  Future<void> login(); // currentStrategy.login(repo) → AuthCubit.login → go('/home')
}
```

---

## 任务 6：login_page.dart — 登录页 UI 重写 `⬜ 待处理`

文件：`client/lib/src/auth/view/login_page.dart`（重写）
组件：`client/lib/src/auth/view/components/`（新建目录）

参考游乐场 `playground/auth/view/login_page.dart` 风格。
LoginPage 为纯 StatefulWidget，通过 `with LoginMixin` 获取状态和方法，`setState` 驱动 UI 刷新，不使用 BlocProvider / BlocListener。
视图按职能拆分为独立组件，LoginPage 只做组装。

### 6.1 视图组件拆分 `⬜`

| 组件 | 文件 | 职责 |
|------|------|------|
| `LabeledInput` | `components/labeled_input.dart` | 带标签 + 竖线分隔的底线输入行 |
| `ActionButton` | `components/action_button.dart` | 启用/禁用态按钮（灰色边线 / 蓝色实心），SetPasswordPage 复用 |
| `AgreementRow` | `components/agreement_row.dart` | 用户协议 + 隐私政策勾选行 |
| `SmsLoginForm` | `components/sms_login_form.dart` | 验证码模式表单（手机号 + 验证码 + 倒计时） |
| `PasswordLoginForm` | `components/password_login_form.dart` | 密码模式表单（账号 + 密码） |

### 6.2 验证码模式 UI `⬜`

- 白色背景，主题色 `#3B82F6`
- 品牌标题 "FLASH IM" + 副标题
- SmsLoginForm（手机号 + 验证码 + 60 秒倒计时）
- AgreementRow + ActionButton

### 6.3 密码模式 UI（账号支持手机号/用户名/邮箱）+ 切换链接 `⬜`

- 底部"使用密码登录 →" / "使用验证码登录 →" 切换
- PasswordLoginForm（账号 + 密码）

### 6.4 登录成功调用 AuthCubit.login + 跳转 `⬜`

- LoginMixin.login() 内部：调用 `AuthRepository.login()` 获取结果
- 成功后调用 `context.read<AuthCubit>().login(token, user, hasPassword)` + `context.go('/home')`
- 失败时 `showToast` 错误信息

---

## 任务 7：AuthCubit 扩展 `⬜ 待处理`

文件：`client/lib/src/auth/logic/auth/auth_cubit.dart`（修改）

### 7.1 新增 onPasswordSet() `⬜`

```dart
void onPasswordSet() {
  if (state.status == AuthStatus.authenticated) {
    emit(AuthState.authenticated(
      token: state.token!,
      user: state.user,
      hasPassword: true,
    ));
  }
}
```

---

## 任务 8：home_page.dart — 三 Tab 主页重写 `⬜ 待处理`

文件：`client/lib/src/home/view/home_page.dart`（重写）

### 8.1 BottomNavigationBar 三 Tab 结构 `⬜`

```dart
// 消息 Tab（Icons.chat_bubble_outline）→ Center(child: Text('暂无消息'))
// 通讯录 Tab（Icons.contacts_outlined）→ Center(child: Text('暂无联系人'))
// 我的 Tab（Icons.person_outline）→ ProfilePage()
// 默认选中"消息" Tab（index: 0）
```

---

## 任务 9：profile_page.dart + set_password_page.dart — "我的"页面 `⬜ 待处理`

文件：`client/lib/src/home/profile/profile_page.dart`（新建）
文件：`client/lib/src/home/profile/set_password_page.dart`（新建）

微信风格列表布局，灰色 AppBar（#EDEDED）+ 白色条目行。

### 9.1 用户信息展示 `⬜`

- 从 `BlocBuilder<AuthCubit, AuthState>` 读取 user
- 头部区域：圆角矩形头像（6px）+ 昵称 + ID + chevron_right
- 信息条目：手机号（icon + label + value 行）
- 不展示 Token

### 9.2 设置/修改密码入口 → 独立页面 `⬜`

- 从 AuthState 读取 `hasPassword`
- `hasPassword == false` → 显示"设置密码"
- `hasPassword == true` → 显示"修改密码"
- 点击跳转 `SetPasswordPage`（Navigator.push），非弹窗
- SetPasswordPage：白色背景，底部下划线输入框 + 圆角按钮（灰色不可点击 / 蓝色可点击，同登录页风格）
- 密码至少 6 位，确认后调用 `authRepository.setPassword()` + `authCubit.onPasswordSet()` + pop 返回

### 9.3 退出登录 `⬜`

- 白色条目，红色居中文字"退出登录"
- 调用 `authRepository.logout()` + `context.read<AuthCubit>().logout()` + `context.go('/login')`

---

## 任务 10：密码设置引导弹窗 `⬜ 待处理`

文件：`client/lib/src/home/view/home_page.dart`（修改）

### 10.1 首次进入 HomePage 且未设密码时弹出引导 `⬜`

- `BlocListener<AuthCubit, AuthState>` 或 `initState` 中检查
- `hasPassword == false` 时弹出 Dialog："建议设置密码，方便下次快速登录"
- "去设置" → 关闭弹窗，直接跳转 SetPasswordPage
- "跳过" → 关闭
- 内存标记避免重复弹出

---

## 任务 11：main.dart + router.dart 组装更新 `⬜ 待处理`

文件：`client/lib/main.dart` + `client/lib/src/router.dart`（修改）

### 11.1 main.dart 组装 `⬜`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final startupRepository = StartupRepository();
  final authCubit = AuthCubit();
  final httpClient = HttpClient(tokenProvider: () => null);
  final authRepository = AuthRepository(dio: httpClient.dio);
  httpClient.tokenProvider = () => authRepository.token ?? authCubit.state.token;

  final router = createRouter(
    startupRepository: startupRepository,
    authRepository: authRepository,
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

- 不再创建 LoginCubit，LoginPage 通过 LoginMixin 管理自身状态
- AuthCubit 挂在 App 顶层，LoginMixin 内部通过 `context.read<AuthCubit>()` 访问

### 11.2 router.dart 更新 `⬜`

- LoginPage 需要 `AuthRepository`（传给 LoginMixin 中的策略对象）
- HomePage 需要 `AuthRepository` 供 ProfilePage 使用
- 通过 `createRouter` 参数传入

---

## 任务 12：编译验证 + 测试路径 `⬜ 待处理`

### 12.1 编译通过 `⬜`

- 零诊断错误

### 12.2 端到端测试 `⬜`

1. 冷启动 → 闪屏 → 无 Token → 跳转登录页
2. 验证码登录 → 跳转主页 → "我的"页面显示用户信息
3. 密码登录 → 同上
4. 未设密码 → 弹出引导 → 设置密码成功
5. 退出登录 → 跳转登录页
6. 重启应用 → 闪屏 → 有 Token → 跳转主页
