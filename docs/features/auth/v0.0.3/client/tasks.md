# 认证增强 — 客户端任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。

全局约束：
- UI 风格参考 `.kiro/skills/flash-im-ui-style`
- 日志使用 fx_logger
- GitHub Client ID 硬编码在客户端（公开值）

---

## 执行顺序

1. ⬜ 任务 1 — pubspec.yaml 添加依赖
2. ⬜ 任务 2 — device_info.dart 设备信息采集
3. ⬜ 任务 3 — auth_repository.dart 新增 loginWithGithub + login 加 deviceInfo
4. ⬜ 任务 4 — github_auth_page.dart WebView 授权页
5. ⬜ 任务 5 — login_mixin.dart 新增 GitHub 登录方法
6. ⬜ 任务 6 — login_page.dart 添加 GitHub 登录按钮
7. ⬜ 任务 7 — 编译验证

---

## 任务 1：pubspec.yaml 添加依赖 `⬜ 待处理`

文件：`client/modules/flash_auth/pubspec.yaml`（修改）

### 1.1 新增 dependencies `⬜`

```yaml
dependencies:
  # ... 现有依赖
  webview_flutter: ^4.10.0
  device_info_plus: ^11.0.0
  package_info_plus: ^8.0.0
  uuid: ^4.5.0
```

---

## 任务 2：device_info.dart — 设备信息采集 `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/data/device_info.dart`（新建）

### 2.1 DeviceInfo 类 `⬜`

```dart
class DeviceInfo {
  final String? platform;
  final String? deviceName;
  final String? deviceId;
  final String? appVersion;

  const DeviceInfo({this.platform, this.deviceName, this.deviceId, this.appVersion});

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'device_name': deviceName,
    'device_id': deviceId,
    'app_version': appVersion,
  };
}
```

### 2.2 collect 静态方法 `⬜`

```dart
static Future<DeviceInfo> collect() async {
  // 1. 用 device_info_plus 获取平台和设备名
  // 2. 用 package_info_plus 获取版本号
  // 3. 从 SharedPreferences 读 device_id，没有则生成 UUID 并存储
  // 返回 DeviceInfo 实例
}
```

逻辑步骤：
1. `DeviceInfoPlugin().deviceInfo` → 提取 model（Android）或 name（iOS）作为 deviceName
2. `Platform.operatingSystem` → platform（android/ios/windows/macos/linux）
3. `PackageInfo.fromPlatform()` → version 作为 appVersion
4. `SharedPreferences.getString('device_id')` → 没有则 `Uuid().v4()` 生成并存储

---

## 任务 3：auth_repository.dart — 新增方法 `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/data/auth_repository.dart`（修改）

### 3.1 login 方法加 deviceInfo 参数 `⬜`

```dart
Future<LoginResult> login(
  String phone,
  String credential,
  String type, {
  DeviceInfo? deviceInfo,
}) async {
  final res = await _dio.post('/auth/login', data: {
    'phone': phone,
    'type': type,
    'credential': credential,
    if (deviceInfo != null) 'device_info': deviceInfo.toJson(),
  });
  ...
}
```

### 3.2 新增 loginWithGithub 方法 `⬜`

```dart
Future<LoginResult> loginWithGithub(String code, {DeviceInfo? deviceInfo}) async {
  final res = await _dio.post('/auth/github', data: {
    'code': code,
    if (deviceInfo != null) 'device_info': deviceInfo.toJson(),
  });
  final result = LoginResult.fromJson(res.data as Map<String, dynamic>);
  await _saveToken(result.token);
  return result;
}
```

---

## 任务 4：github_auth_page.dart — WebView 授权页 `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/view/github_auth_page.dart`（新建）

### 4.1 常量定义 `⬜`

```dart
const _githubClientId = '你的Client_ID';
const _redirectUri = 'http://localhost/callback';
const _authUrl = 'https://github.com/login/oauth/authorize'
    '?client_id=$_githubClientId'
    '&redirect_uri=$_redirectUri'
    '&scope=read:user';
```

### 4.2 GitHubAuthPage Widget `⬜`

```dart
class GitHubAuthPage extends StatefulWidget {
  const GitHubAuthPage({super.key});

  @override
  State<GitHubAuthPage> createState() => _GitHubAuthPageState();
}
```

### 4.3 WebView 加载 + URL 拦截 `⬜`

```dart
// initState 中：
// 1. 创建 WebViewController
// 2. 设置 NavigationDelegate，在 onNavigationRequest 中：
//    - 检查 URL 是否以 _redirectUri 开头
//    - 如果是，提取 ?code= 参数
//    - Navigator.pop(context, code)
//    - return NavigationDecision.prevent
// 3. controller.loadRequest(Uri.parse(_authUrl))
```

### 4.4 UI 结构 `⬜`

```dart
// Scaffold + AppBar（标题"GitHub 登录"，左侧返回按钮）
// body: WebViewWidget(controller: _controller)
```

---

## 任务 5：login_mixin.dart — 新增 GitHub 登录 `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/logic/login/login_mixin.dart`（修改）

### 5.1 新增 loginWithGithub 方法 `⬜`

```dart
Future<void> loginWithGithub(BuildContext context) async {
  // 1. Navigator.push GitHubAuthPage，等待返回 code
  // 2. 如果 code 为 null（用户取消），return
  // 3. setState loading = true
  // 4. DeviceInfo.collect()
  // 5. authRepository.loginWithGithub(code, deviceInfo: info)
  // 6. onLoginSuccess(result)
  // 7. 异常处理：toast 提示
}
```

### 5.2 修改现有 login 调用，传入 deviceInfo `⬜`

在 LoginMixin 的 `login()` 方法中，调用 `authRepository.login()` 前先采集设备信息：

```dart
final deviceInfo = await DeviceInfo.collect();
final result = await authRepository.login(phone, credential, type, deviceInfo: deviceInfo);
```

---

## 任务 6：login_page.dart — 添加 GitHub 按钮 `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/view/login_page.dart`（修改）

### 6.1 在模式切换下方添加分割线 + GitHub 按钮 `⬜`

在 `_buildModeToggle()` 下方添加：

```dart
const SizedBox(height: 32),
_buildDividerWithText('其他登录方式'),
const SizedBox(height: 16),
_buildGithubButton(),
```

### 6.2 _buildDividerWithText Widget `⬜`

```dart
// Row: [Expanded(Divider), Padding(Text("其他登录方式")), Expanded(Divider)]
// 文字颜色 #999999，分割线颜色 #E0E0E0
```

### 6.3 _buildGithubButton Widget `⬜`

```dart
// GestureDetector → Container（白色背景、灰色边框、圆角 8）
// 内部 Row：GitHub 图标 + "GitHub 登录" 文字
// 点击调用 loginWithGithub(context)
// 注意：只在移动端显示（Platform.isAndroid || Platform.isIOS），桌面端隐藏
```

---

## 任务 7：编译验证 `⬜ 待处理`

### 7.1 flutter analyze `⬜`

```bash
cd client && flutter analyze
```

期望：No issues found（忽略子模块 flutter_svg 的已知 warning）。

### 7.2 手动验证 `⬜`

- 登录页显示 GitHub 按钮
- 点击后打开 WebView
- 授权后自动关闭 WebView 并登录成功
- 手机号登录仍正常
