# fx_updater + 主项目集成 — 前端任务清单

基于 client/design.md 设计，列出需要创建/修改的具体细节。
全局约束：fx_updater 包不依赖 dio、不依赖任何闪讯业务代码。通用能力通过回调/接口注入。

---

## 执行顺序

1. ⬜ 任务 1 — fx_updater 包配置（无依赖）
2. ⬜ 任务 2 — AppVersion 版本号模型（无依赖）
3. ⬜ 任务 3 — UpdateInfo 更新信息模型（依赖任务 2）
4. ⬜ 任务 4 — UpdateChecker 检查器（依赖任务 3）
5. ⬜ 任务 5 — UpdateStrategy 策略接口（依赖任务 3）
6. ⬜ 任务 6 — UpdateDialog 通用弹窗（依赖任务 3）
7. ⬜ 任务 7 — barrel export（依赖任务 2-6）
8. ⬜ 任务 8 — 主项目集成（依赖任务 7）
9. ⬜ 任务 9 — 编译验证

---

## 任务 1：fx_updater 包配置 `⬜ 待处理`

文件：`client/packages/fx_updater/pubspec.yaml`（新建）

```yaml
name: fx_updater
description: 通用应用更新框架 - 版本检测 + 策略接口 + 弹窗 UI
version: 0.1.0
publish_to: none

environment:
  sdk: ^3.11.1
  flutter: ">=1.17.0"

dependencies:
  flutter:
    sdk: flutter
  url_launcher: ^6.2.0
  package_info_plus: ^8.0.0
```

---

## 任务 2：AppVersion 版本号模型 `⬜ 待处理`

文件：`client/packages/fx_updater/lib/src/app_version.dart`（新建）

### 2.1 版本号解析与比较 `⬜`

```dart
class AppVersion implements Comparable<AppVersion> {
  final int major;
  final int minor;
  final int patch;

  const AppVersion(this.major, this.minor, this.patch);

  factory AppVersion.parse(String version)
  // 解析 "x.y.z" 格式，忽略 +buildNumber 部分

  @override
  int compareTo(AppVersion other)
  // major → minor → patch 逐级比较

  bool operator >(AppVersion other);
  bool operator <(AppVersion other);
  bool operator >=(AppVersion other);
  bool operator <=(AppVersion other);

  @override
  String toString() => '$major.$minor.$patch';
}
```

---

## 任务 3：UpdateInfo 更新信息模型 `⬜ 待处理`

文件：`client/packages/fx_updater/lib/src/update_info.dart`（新建）

### 3.1 数据模型 `⬜`

```dart
class UpdateInfo {
  final String version;
  final String downloadUrl;
  final int fileSize;
  final String? sha256;
  final String releaseNotes;
  final bool forceUpdate;

  const UpdateInfo({...});

  factory UpdateInfo.fromJson(Map<String, dynamic> json)
  // version = json['version']
  // downloadUrl = json['download_url']
  // fileSize = json['file_size'] ?? 0
  // sha256 = json['sha256']
  // releaseNotes = json['release_notes'] ?? ''
  // forceUpdate = json['force_update'] ?? false
}
```

### 3.2 检查结果 `⬜`

```dart
sealed class UpdateCheckResult {}

class UpdateAvailable extends UpdateCheckResult {
  final UpdateInfo info;
  UpdateAvailable(this.info);
}

class UpdateNotNeeded extends UpdateCheckResult {}

class UpdateCheckFailed extends UpdateCheckResult {
  final String error;
  UpdateCheckFailed(this.error);
}
```

---

## 任务 4：UpdateChecker 检查器 `⬜ 待处理`

文件：`client/packages/fx_updater/lib/src/update_checker.dart`（新建）

### 4.1 检查逻辑 `⬜`

```dart
typedef FetchUpdateInfo = Future<UpdateInfo?> Function();

class UpdateChecker {
  final AppVersion currentVersion;
  final FetchUpdateInfo fetchUpdateInfo;

  UpdateChecker({required this.currentVersion, required this.fetchUpdateInfo});

  Future<UpdateCheckResult> check() async
  // 1. 调用 fetchUpdateInfo()
  // 2. 返回 null → UpdateCheckFailed('无法获取更新信息')
  // 3. 解析 latestVersion = AppVersion.parse(info.version)
  // 4. latestVersion > currentVersion → UpdateAvailable(info)
  // 5. 否则 → UpdateNotNeeded()
  // 6. 异常 catch → UpdateCheckFailed(e.toString())
}
```

---

## 任务 5：UpdateStrategy 策略接口 `⬜ 待处理`

文件：`client/packages/fx_updater/lib/src/update_strategy.dart`（新建）

### 5.1 策略抽象 `⬜`

```dart
abstract class UpdateStrategy {
  Future<void> execute(UpdateInfo info);
}
```

### 5.2 URL 跳转策略（iOS/鸿蒙） `⬜`

```dart
class UrlLaunchStrategy implements UpdateStrategy {
  @override
  Future<void> execute(UpdateInfo info) async
  // launchUrl(Uri.parse(info.downloadUrl), mode: LaunchMode.externalApplication)
}
```

### 5.3 空策略（Web） `⬜`

```dart
class NoOpStrategy implements UpdateStrategy {
  @override
  Future<void> execute(UpdateInfo info) async {}
}
```

注意：`DownloadStrategy`（Android/桌面端下载 APK/安装包）由主项目自己实现（因为依赖 dio），fx_updater 不提供。

---

## 任务 6：UpdateDialog 通用弹窗 `⬜ 待处理`

文件：`client/packages/fx_updater/lib/src/update_dialog.dart`（新建）

### 6.1 弹窗组件 `⬜`

```dart
class UpdateDialog extends StatelessWidget {
  final UpdateInfo info;
  final VoidCallback onUpdate;
  final VoidCallback? onDismiss;

  // 构建内容：
  // - 标题："发现新版本 v{info.version}"
  // - 更新日志：info.releaseNotes
  // - 文件大小：info.fileSize > 0 时显示 "{xx} MB"
  // - 底部按钮：
  //   - forceUpdate=false → "稍后" + "立即更新"
  //   - forceUpdate=true  → 只有 "立即更新"

  static Future<void> show(BuildContext context, {
    required UpdateInfo info,
    required VoidCallback onUpdate,
    VoidCallback? onDismiss,
  })
  // showDialog(barrierDismissible: !info.forceUpdate, ...)
}
```

---

## 任务 7：barrel export `⬜ 待处理`

文件：`client/packages/fx_updater/lib/fx_updater.dart`（新建）

```dart
library;

export 'src/app_version.dart';
export 'src/update_info.dart';
export 'src/update_checker.dart';
export 'src/update_strategy.dart';
export 'src/update_dialog.dart';
```

---

## 任务 8：主项目集成 `⬜ 待处理`

### 8.1 添加依赖 `⬜`

文件：`client/pubspec.yaml`（修改）

```yaml
  fx_updater:
    path: packages/fx_updater
```

### 8.2 集成逻辑 `⬜`

文件：`client/lib/src/update/update_trigger.dart`（新建）

```dart
import 'package:fx_updater/fx_updater.dart';

class UpdateTrigger {
  final Dio _dio;
  final String appId;
  final String baseUrl;

  Future<void> checkAndPrompt(BuildContext context) async
  // 1. 获取本地版本：PackageInfo.fromPlatform()
  // 2. 构建 UpdateChecker，注入 fetch 回调：
  //    fetch = () => _dio.get('/api/app/version?app_id=$appId&platform=$platform')
  //                     .then((r) => UpdateInfo.fromJson(r.data))
  // 3. checker.check()
  // 4. 如果 UpdateAvailable → UpdateDialog.show(...)
  // 5. onUpdate 回调中调用 _getStrategy().execute(info)

  UpdateStrategy _getStrategy()
  // Web → NoOpStrategy
  // iOS → UrlLaunchStrategy()
  // 鸿蒙 → UrlLaunchStrategy()
  // Android/桌面 → DownloadInstallStrategy（本文件内实现，用 dio 下载）
}
```

### 8.3 Android/桌面下载策略 `⬜`

在 `update_trigger.dart` 中实现（因为依赖 dio）：

```dart
class DownloadInstallStrategy implements UpdateStrategy {
  final Dio dio;

  @override
  Future<void> execute(UpdateInfo info) async
  // 1. 确定保存路径（getTemporaryDirectory + fileName）
  // 2. dio.download(info.downloadUrl, savePath)
  // 3. Android: 调起安装器（OpenFile 或 install_plugin）
  // 4. 桌面: launchUrl(Uri.file(savePath)) 打开文件
}
```

### 8.4 HomePage 触发 `⬜`

文件：`client/lib/src/home/view/home_page.dart`（修改）

在 `initState` 中添加：

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!kIsWeb) _checkUpdate();
});

void _checkUpdate() {
  UpdateTrigger(dio: context.read<Dio>(), appId: '1', baseUrl: AppConfig.baseUrl)
      .checkAndPrompt(context);
}
```

---

## 任务 9：编译验证 `⬜ 待处理`

### 9.1 flutter analyze `⬜`

```bash
flutter analyze
```

### 9.2 手动验证 `⬜`

- 本地版本设为 "0.0.1"，后端有 "1.0.0" → 弹窗出现
- 本地版本 = 后端版本 → 无弹窗
- force_update=true → 弹窗无"稍后"按钮
- 断网 → 静默失败，无弹窗
