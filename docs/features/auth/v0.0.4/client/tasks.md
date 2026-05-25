# 认证增强（Apple 登录 + 邮箱登录）— 前端任务清单

基于 client/design.md 设计，列出需要创建/修改的具体细节。

全局约束：
- 日志使用 fx_logger，不用 print
- async 操作后使用 BuildContext 前检查 mounted
- 复用现有 LoginStrategy 抽象和 LabeledInput 组件

---

## 执行顺序

1. ✅ 任务 1 — AuthRepository 扩展（sendEmailCode + loginWithApple）
2. ✅ 任务 2 — EmailLoginStrategy（邮箱验证码策略）
3. ✅ 任务 3 — EmailLoginForm 组件
4. ✅ 任务 4 — LoginMixin 扩展（Tab 状态 + emailStrategy）
5. ✅ 任务 5 — LoginPage 改造（顶部 Tab + Apple 图标）
6. ✅ 任务 6 — 添加 sign_in_with_apple 依赖
7. ✅ 任务 7 — 编译验证

---

## 任务 1：AuthRepository 扩展 `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/data/auth_repository.dart`（修改）

### 1.1 新增 sendEmailCode 方法 `⬜`

```dart
/// 发送邮箱验证码
Future<String?> sendEmailCode(String email) async {
  final res = await _dio.post('/auth/email/code', data: {'email': email});
  return res.data['code'] as String?; // debug 模式返回 code，release 返回 null
}
```

### 1.2 新增 loginWithApple 方法 `⬜`

```dart
/// Apple OAuth 登录
Future<LoginResult> loginWithApple(String identityToken, {DeviceInfo? deviceInfo}) async {
  final res = await _dio.post('/auth/apple', data: {
    'identity_token': identityToken,
    if (deviceInfo != null) 'device_info': deviceInfo.toJson(),
  });
  final loginResult = LoginResult.fromJson(res.data as Map<String, dynamic>);
  await _saveToken(loginResult.token);
  return loginResult;
}
```

---

## 任务 2：EmailLoginStrategy `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/logic/login/strategy/email_login_strategy.dart`（新建）

### 2.1 类定义 `⬜`

```dart
typedef SendEmailCodeCallback = Future<String?> Function(String email);

class EmailLoginStrategy extends LoginStrategy {
  final SendEmailCodeCallback sendEmailCodeCallback;
  final VoidCallback _refresh;

  final emailCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  int countdown = 0;
  Timer? _timer;
}
```

### 2.2 校验逻辑 `⬜`

```dart
String get email => emailCtrl.text.trim();
String get credential => codeCtrl.text.trim();
bool get isEmailValid => email.contains('@') && email.contains('.');
@override
bool get isValid => isEmailValid && credential.isNotEmpty;
bool get canSendCode => countdown <= 0;
```

### 2.3 sendCode 方法 `⬜`

逻辑步骤：
1. 校验 isEmailValid，不合法则 showToast
2. 调用 sendEmailCodeCallback(email)
3. 如果返回 code（debug 模式），自动填入 codeCtrl
4. 启动 60 秒倒计时

### 2.4 login 方法 `⬜`

```dart
@override
Future<LoginResult> login(AuthRepository repo, {DeviceInfo? deviceInfo}) {
  return repo.login(email, credential, 'email', deviceInfo: deviceInfo);
}
```

### 2.5 listen + dispose `⬜`

同 SmsLoginStrategy 模式：addListener(_refresh) + dispose controllers + cancel timer。

---

## 任务 3：EmailLoginForm 组件 `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/view/components/email_login_form.dart`（新建）

### 3.1 Widget 定义 `⬜`

```dart
class EmailLoginForm extends StatelessWidget {
  final EmailLoginStrategy strategy;
  final bool isLoading;
  final VoidCallback onSendCode;
}
```

### 3.2 UI 结构 `⬜`

两行输入，同 SmsLoginForm 布局：
- 第一行：label="邮箱"，TextField（keyboardType: emailAddress，hint: "请输入邮箱"）
- 第二行：label="验证码"，TextField + trailing "获取验证码"（带倒计时）

复用 `LabeledInput` 组件。

---

## 任务 4：LoginMixin 扩展 `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/logic/login/login_mixin.dart`（修改）

### 4.1 新增 LoginTab enum `⬜`

```dart
enum LoginTab { email, phone }
```

### 4.2 新增状态字段 `⬜`

```dart
late final EmailLoginStrategy emailStrategy;
LoginTab tab = LoginTab.phone; // 默认手机号 Tab
bool get isEmailTab => tab == LoginTab.email;
```

### 4.3 修改 currentStrategy getter `⬜`

```dart
LoginStrategy get currentStrategy {
  if (isEmailTab) return emailStrategy;
  return isSmsMode ? smsStrategy : passwordStrategy;
}
```

### 4.4 initMixin 中初始化 emailStrategy `⬜`

```dart
emailStrategy = EmailLoginStrategy(
  sendEmailCodeCallback: (email) => widget.authRepository.sendEmailCode(email),
  refresh: () => setState(() {}),
);
emailStrategy.listen();
```

### 4.5 disposeMixin 中释放 `⬜`

```dart
emailStrategy.dispose();
```

### 4.6 新增 switchTab 方法 `⬜`

```dart
void switchTab(LoginTab newTab) {
  setState(() {
    tab = newTab;
    mode = LoginMode.sms; // 切换 Tab 时重置为验证码模式
  });
}
```

### 4.7 新增 loginWithApple 方法 `⬜`

```dart
Future<void> loginWithApple(BuildContext context) async {
  if (!agreed) {
    showToast('请先阅读并同意用户协议和隐私政策');
    return;
  }
  setState(() => isLoading = true);
  try {
    // 调用 sign_in_with_apple
    final credential = await SignInWithApple.getAppleIDCredential(scopes: [AppleIDAuthorizationScopes.email]);
    final identityToken = credential.identityToken;
    if (identityToken == null) throw Exception('未获取到 identityToken');
    final deviceInfo = await DeviceInfo.collect();
    final result = await widget.authRepository.loginWithApple(identityToken, deviceInfo: deviceInfo);
    if (!mounted) return;
    widget.onLoginSuccess(result);
  } catch (e) {
    if (mounted) showToast('Apple 登录失败: $e');
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}
```

### 4.8 sendEmailCode 协议校验 `⬜`

在 LoginPage 中调用 emailStrategy.sendCode 前，检查 agreed（同 sendSms 的处理）。

---

## 任务 5：LoginPage 改造 `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/view/login_page.dart`（修改）

### 5.1 顶部 Tab 组件 `⬜`

在 `_BrandHeader` 下方、表单上方，添加 Tab 切换：

```dart
_buildLoginTab(),
const SizedBox(height: 32),
```

Tab 样式：两个文字并排，选中项加蓝色下划线，未选中灰色。

```dart
Widget _buildLoginTab() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _buildTabItem('邮箱登录', LoginTab.email),
      const SizedBox(width: 32),
      _buildTabItem('手机号登录', LoginTab.phone),
    ],
  );
}

Widget _buildTabItem(String label, LoginTab targetTab) {
  final selected = tab == targetTab;
  return GestureDetector(
    onTap: () => switchTab(targetTab),
    child: Column(
      children: [
        Text(label, style: TextStyle(
          fontSize: 16,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? const Color(0xFF333333) : const Color(0xFF999999),
        )),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 2,
          color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
        ),
      ],
    ),
  );
}
```

### 5.2 表单区域按 Tab 切换 `⬜`

```dart
if (isEmailTab)
  EmailLoginForm(
    strategy: emailStrategy,
    isLoading: isLoading,
    onSendCode: () async {
      if (!agreed) {
        showToast('请先阅读并同意用户协议和隐私政策');
        return;
      }
      await emailStrategy.sendCode();
    },
  )
else if (isSmsMode)
  SmsLoginForm(...)
else
  PasswordLoginForm(...)
```

### 5.3 底部"其他登录方式"增加 Apple `⬜`

在 `_buildOtherLoginRow` 中，iOS 平台增加 Apple 图标：

```dart
if (Platform.isIOS) ...[
  _buildAppleItem(),
  const SizedBox(width: 24),
],
if (Platform.isAndroid || Platform.isIOS) ...[
  _buildGithubItem(),
  const SizedBox(width: 24),
],
```

Apple 图标使用 Icons.apple 或 sign_in_with_apple 提供的按钮样式。

### 5.4 底部"密码登录"切换逻辑适配 `⬜`

邮箱 Tab 下不显示"密码登录/验证码登录"切换按钮（首版邮箱只支持验证码登录）。底部切换仅在手机号 Tab 下显示：

```dart
_buildOtherLoginItem(
  icon: Icons.lock_outline,
  label: isSmsMode ? '密码登录' : '验证码登录',
  onTap: toggleMode,
),
// 仅手机号 Tab 显示此项
```

邮箱密码登录由后端自动处理（验证码不匹配时尝试密码），无需前端额外入口。

---

## 任务 6：添加依赖 `⬜ 待处理`

文件：`client/modules/flash_auth/pubspec.yaml`（修改）

### 6.1 新增 sign_in_with_apple `⬜`

```yaml
dependencies:
  sign_in_with_apple: ^6.1.0
```

同时在主项目 `client/pubspec.yaml` 的 `dependency_overrides` 中添加（如果子模块解析不了）：

```yaml
sign_in_with_apple: ^6.1.0
```

### 6.2 iOS 配置提醒 `⬜`

使用 sign_in_with_apple 需要：
1. Xcode → Runner → Signing & Capabilities → 添加 "Sign in with Apple"
2. Apple Developer 后台 → Identifiers → 对应 App ID → 勾选 "Sign in with Apple"

这两步需要在 Mac 上手动操作，非代码改动。

---

## 任务 7：编译验证 `⬜ 待处理`

### 7.1 flutter analyze `⬜`

```bash
cd client
flutter analyze
```

确认零错误。

### 7.2 真机验证 `⬜`

- 切换 Tab：邮箱 ↔ 手机号，表单正确切换
- 邮箱获取验证码：debug 模式自动填入
- 邮箱验证码登录：进入主页
- 频率限制：60 秒内重复点击，toast 提示
- Apple 登录（iOS）：系统弹窗 → 登录成功
- 协议校验：未勾选时所有登录入口都拦截
