# Auth — 前端任务清单（桌面端扫码登录）

基于 client/design.md 设计，列出需要创建/修改的具体细节。
二维码生成使用 qr_flutter 包。轮询使用 Timer.periodic。桌面端判断使用 Platform。

---

## 执行顺序

1. ⬜ 任务 1 — flash_auth pubspec.yaml 添加 qr_flutter 依赖
2. ⬜ 任务 2 — auth_repository.dart 新增 4 个扫码方法
3. ⬜ 任务 3 — login_mixin.dart 扩展 LoginTab 枚举
4. ⬜ 任务 4 — login_segment_tab.dart 支持桌面端四 Tab
5. ⬜ 任务 5 — qr_login_form.dart 新建扫码登录表单
6. ⬜ 任务 6 — login_page.dart 桌面端四 Tab + 去三方登录
7. ⬜ 任务 7 — scan_page.dart 支持 flashim://scan 路由
8. ⬜ 任务 8 — scan_confirm_page.dart 新建扫码确认页
9. ⬜ 任务 9 — flutter analyze 验证

---

## 任务 1：添加 qr_flutter 依赖 `⬜ 待处理`

文件：`client/modules/flash_auth/pubspec.yaml`（修改）

### 1.1 添加依赖 `⬜`

在 dependencies 中添加：

```yaml
qr_flutter: ^4.1.0
```

---

## 任务 2：auth_repository.dart — 新增扫码方法 `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/data/auth_repository.dart`（修改）

### 2.1 新增数据类 `⬜`

在文件中或新建 `scan_models.dart`：

```dart
class ScanCreateResult {
  final String token;
  final String qrContent;
  final DateTime expiresAt;
  ScanCreateResult({required this.token, required this.qrContent, required this.expiresAt});
  factory ScanCreateResult.fromJson(Map<String, dynamic> json) => ScanCreateResult(
    token: json['token'],
    qrContent: json['qr_content'],
    expiresAt: DateTime.parse(json['expires_at']),
  );
}

class ScanStatusResult {
  final String status;  // pending/scanned/confirmed/expired/cancelled
  final String? token;  // JWT（confirmed 时有值）
  final int? userId;
  ScanStatusResult({required this.status, this.token, this.userId});
  factory ScanStatusResult.fromJson(Map<String, dynamic> json) => ScanStatusResult(
    status: json['status'],
    token: json['token'],
    userId: json['user_id'],
  );
}
```

### 2.2 新增 4 个方法 `⬜`

```dart
/// 创建扫码会话（桌面端调用，无需认证）
Future<ScanCreateResult> createScanSession() async {
  final res = await _dio.post('/auth/scan/create');
  return ScanCreateResult.fromJson(res.data);
}

/// 查询扫码状态（桌面端轮询，无需认证）
Future<ScanStatusResult> getScanStatus(String token) async {
  final res = await _dio.get('/auth/scan/status', queryParameters: {'token': token});
  return ScanStatusResult.fromJson(res.data);
}

/// 手机端扫码/确认（需认证）
Future<void> confirmScan(String scanToken, String action) async {
  await _dio.post('/auth/scan/confirm', data: {'scan_token': scanToken, 'action': action});
}

/// 手机端取消（需认证）
Future<void> cancelScan(String scanToken) async {
  await _dio.post('/auth/scan/cancel', data: {'scan_token': scanToken});
}
```

---

## 任务 3：login_mixin.dart — 扩展 LoginTab `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/logic/login/login_mixin.dart`（修改）

### 3.1 扩展枚举 `⬜`

```dart
enum LoginTab { email, phone, password, scan }
```

### 3.2 调整 currentStrategy `⬜`

scan Tab 不需要 LoginStrategy（不走表单登录），在 `canLogin` 和 `currentStrategy` 中处理：
- `isEmailTab` / `isPhoneTab` / `isPasswordTab` / `isScanTab` getter
- scan Tab 时 canLogin = false（不显示登录按钮）

---

## 任务 4：login_segment_tab.dart — 桌面端四 Tab `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/view/components/login_segment_tab.dart`（修改）

### 4.1 新增 isDesktop 参数 `⬜`

```dart
class LoginSegmentTab extends StatelessWidget {
  final LoginTab current;
  final ValueChanged<LoginTab> onChanged;
  final bool enableSMS;
  final bool isDesktop;  // 新增
}
```

### 4.2 桌面端四 Tab 布局 `⬜`

当 `isDesktop = true` 时，显示四个 Tab：
- 邮箱登录（email）
- 手机号登录（phone）— 如果 enableSMS
- 密码登录（password）
- 扫码登录（scan）

移动端保持原有两 Tab 不变。

---

## 任务 5：qr_login_form.dart — 新建 `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/view/components/qr_login_form.dart`（新建）

### 5.1 组件结构 `⬜`

```dart
class QrLoginForm extends StatefulWidget {
  final AuthRepository authRepository;
  final OnLoginSuccess onLoginSuccess;
}
```

### 5.2 核心逻辑 `⬜`

- initState：调用 `_createSession()` 生成二维码
- `_createSession()`：调用 `authRepository.createScanSession()`，获取 qrContent，启动轮询 Timer
- `_pollStatus()`：每 2 秒调用 `getScanStatus`，根据状态更新 UI
  - pending：显示二维码
  - scanned：显示"已扫码，等待确认"
  - confirmed：调用 `onLoginSuccess`（构造 LoginResult）
  - expired：显示过期遮罩 + 刷新按钮
  - cancelled：回到显示二维码
- dispose：取消 Timer

### 5.3 UI 结构 `⬜`

```
Column(
  QrImageView(data: qrContent, size: 200)   // 或过期遮罩
  SizedBox(height: 16)
  Text(状态提示文字)
  if (expired) TextButton("点击刷新")
)
```

---

## 任务 6：login_page.dart — 桌面端改造 `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/view/login_page.dart`（修改）

### 6.1 判断桌面端 `⬜`

```dart
bool get _isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
```

### 6.2 传递 isDesktop 给 LoginSegmentTab `⬜`

```dart
LoginSegmentTab(current: tab, onChanged: switchTab, enableSMS: widget.enableSMS, isDesktop: _isDesktop)
```

### 6.3 _buildForm 新增 scan 分支 `⬜`

```dart
if (tab == LoginTab.scan) {
  return QrLoginForm(authRepository: widget.authRepository, onLoginSuccess: widget.onLoginSuccess);
}
```

### 6.4 桌面端隐藏 OtherLoginRow `⬜`

```dart
if (!_isDesktop) OtherLoginRow(...)
```

### 6.5 桌面端隐藏 ActionButton（scan Tab 时） `⬜`

scan Tab 不需要登录按钮（自动登录）。

---

## 任务 7：ScanPage 迁移到 flash_shared `⬜ 待处理`

文件：
- `client/modules/flash_shared/lib/src/scan_page.dart`（新建，从 flash_im_friend 迁移）
- `client/modules/flash_shared/lib/flash_shared.dart`（修改：导出）
- `client/modules/flash_im_friend/lib/src/view/scan_page.dart`（删除）
- 调用方更新 import

### 7.1 迁移 ScanPage 到 flash_shared `⬜`

ScanPage 改为通用组件，通过回调分发不同 scheme：

```dart
/// 通用扫码页，扫到不同 scheme 通过回调分发
class ScanPage extends StatefulWidget {
  /// flashim://user/{id} 回调
  final void Function(String userId)? onUserScanned;
  /// flashim://scan/{token} 回调
  final void Function(String scanToken)? onScanLogin;
}
```

去掉对 FriendRepository 的依赖，纯扫码 + 路由分发。

### 7.2 更新 flash_im_friend 中的调用方 `⬜`

原来 `ScanPage(repository: repo)` 改为从 flash_shared 导入，传入回调：

```dart
ScanPage(
  onUserScanned: (userId) => _fetchAndNavigate(userId),
  onScanLogin: (token) => _navigateToConfirm(token),
)
```

### 7.3 flash_shared pubspec.yaml 添加 mobile_scanner 依赖 `⬜`

```yaml
mobile_scanner: ^6.0.0
```

---

## 任务 8：scan_confirm_page.dart — 新建（flash_auth） `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/view/scan_confirm_page.dart`（新建）

### 8.1 页面结构 `⬜`

```dart
class ScanConfirmPage extends StatefulWidget {
  final String scanToken;
  final AuthRepository authRepository;
}
```

### 8.2 核心逻辑 `⬜`

- initState：调用 `authRepository.confirmScan(scanToken, 'scan')` 标记已扫码
- 确认按钮：调用 `authRepository.confirmScan(scanToken, 'confirm')`，成功后显示"登录成功"并 pop
- 取消按钮：调用 `authRepository.cancelScan(scanToken)`，pop 返回

### 8.3 UI 结构 `⬜`

```
Scaffold(
  appBar: "扫码登录"
  body: Column(
    Icon(确认图标)
    Text("即将登录桌面端闪讯")
    Row(
      OutlinedButton("取消")
      ElevatedButton("确认登录")
    )
  )
)
```

---

## 任务 9：flutter analyze 验证 `⬜ 待处理`

### 9.1 执行 analyze `⬜`

```bash
flutter analyze
```

确保零错误零警告。
