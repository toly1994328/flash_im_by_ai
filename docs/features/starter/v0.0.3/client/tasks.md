# fx_updater + fx_install_android + 主项目集成 — 前端任务清单

基于 client/design.md 设计，列出需要创建/修改的具体细节。
全局约束：fx_updater 包不依赖 dio、不依赖任何闪讯业务代码。通用能力通过回调/接口注入。

---

## 执行顺序

1. ✅ 任务 1 — fx_updater 包配置
2. ✅ 任务 2 — AppVersion 版本号模型
3. ✅ 任务 3 — UpdateInfo 更新信息模型
4. ✅ 任务 4 — UpdateChecker 检查器
5. ✅ 任务 5 — UpdateStrategy 策略接口
6. ✅ 任务 6 — UpdateDialog 通用弹窗（含下载进度）
7. ✅ 任务 7 — FxUpdater 全局状态管理
8. ✅ 任务 8 — barrel export
9. ✅ 任务 9 — fx_install_android 原生安装插件
10. ✅ 任务 10 — AppChannel 渠道标识
11. ✅ 任务 11 — 主项目集成（UpdateTrigger）
12. ✅ 任务 12 — Android Flavor 配置
13. ✅ 任务 13 — 构建脚本适配
14. ✅ 任务 14 — 发布到 pub

---

## 任务 1：fx_updater 包配置 `✅ 已完成`

文件：`client/packages/fx_updater/pubspec.yaml`

```yaml
name: fx_updater
description: 通用应用更新框架 - 版本检测 + 策略接口 + 弹窗 UI
version: 0.1.0
publish_to: https://pub.dev

environment:
  sdk: ^3.11.1
  flutter: ">=1.17.0"

dependencies:
  flutter:
    sdk: flutter
  url_launcher: ^6.2.0
  path_provider: ^2.1.5
  path: ^1.9.1
```

---

## 任务 2：AppVersion 版本号模型 `✅ 已完成`

文件：`client/packages/fx_updater/lib/src/data/app_version.dart`

- 解析 "x.y.z" 格式（忽略 +buildNumber）
- 实现 Comparable，逐级比较 major → minor → patch
- 提供 `>`, `<`, `>=`, `<=` 运算符

---

## 任务 3：UpdateInfo 更新信息模型 `✅ 已完成`

文件：`client/packages/fx_updater/lib/src/data/update_info.dart`

```dart
class UpdateInfo {
  final String version;
  final String downloadUrl;
  final int fileSize;
  final String? sha256;         // 后端在构建时通过 calculate.py 计算
  final String releaseNotes;
  final bool forceUpdate;

  factory UpdateInfo.fromJson(Map<String, dynamic> json);
  String get fileSizeText;      // "25.3 MB"
}

sealed class UpdateCheckResult {}
class UpdateAvailable extends UpdateCheckResult { ... }
class UpdateNotNeeded extends UpdateCheckResult {}
class UpdateCheckFailed extends UpdateCheckResult { ... }
```

---

## 任务 4：UpdateChecker 检查器 `✅ 已完成`

文件：`client/packages/fx_updater/lib/src/logic/update_checker.dart`

- 接受 `currentVersion` + `fetchUpdateInfo` 回调
- 调用回调获取 UpdateInfo → 比较版本 → 返回 UpdateCheckResult
- 异常 catch → UpdateCheckFailed

---

## 任务 5：UpdateStrategy 策略接口 `✅ 已完成`

文件：`client/packages/fx_updater/lib/src/logic/update_strategy.dart`

| 策略类 | 用途 | 依赖 |
|--------|------|------|
| `AndroidUpdateStrategy` | 下载 + 安装 APK | 通过 downloadFile + installApk 回调注入 |
| `DesktopUpdateStrategy` | 下载 + 打开文件 | 通过 downloadFile 回调注入 |
| `MacOSUpdateStrategy` | 跳转浏览器下载 | url_launcher |
| `UrlLaunchStrategy` | 跳转商店（iOS/鸿蒙/Google） | url_launcher |
| `NoOpStrategy` | Web 端空操作 | — |

fx_updater 不依赖 dio，下载逻辑由使用方通过回调注入。

---

## 任务 6：UpdateDialog 通用弹窗 `✅ 已完成`

文件：`client/packages/fx_updater/lib/src/view/update_dialog.dart`

功能：
- 始终显示版本号 + 更新日志 + 文件大小
- 支持 downloadHandler 回调（有则走下载流程，无则 onUpdate 直接跳转）
- 支持 installHandler 回调（下载完成后点击"安装"时调用）
- 内置状态机：info → downloading（进度条） → completed → failed
- forceUpdate=true 时弹窗不可关闭
- 支持恢复已有下载状态（通过 FxUpdater 单例）

---

## 任务 7：FxUpdater 全局状态管理 `✅ 已完成`

文件：`client/packages/fx_updater/lib/src/logic/update_manager.dart`

- 单例模式，持有最新检测结果
- 通过 Stream 暴露状态变更（红点/弹窗/设置页消费）
- 进度流：下载百分比实时推送
- 下载状态跟踪：isDownloading / isDownloaded / downloadedFilePath
- dismiss() 清除红点

---

## 任务 8：barrel export `✅ 已完成`

文件：`client/packages/fx_updater/lib/fx_updater.dart`

```dart
// data
export 'src/data/app_version.dart';
export 'src/data/update_info.dart';

// logic
export 'src/logic/update_checker.dart';
export 'src/logic/update_manager.dart';
export 'src/logic/update_strategy.dart';

// view
export 'src/view/update_dialog.dart';
export 'src/view/update_badge.dart';
```

---

## 任务 9：fx_install_android 原生安装插件 `✅ 已完成`

文件结构：
```
packages/fx_install_android/
├── pubspec.yaml                    # Flutter plugin 声明（已发 pub）
├── lib/fx_install_android.dart     # Dart API: FxInstall.apk(path) → InstallResult
└── android/
    ├── build.gradle.kts            # compileSdk 35, androidx.core
    └── src/main/
        ├── AndroidManifest.xml     # 自带 FxInstallFileProvider
        ├── res/xml/fx_install_paths.xml
        └── kotlin/.../
            ├── FxInstallPlugin.kt        # 主逻辑（ActivityAware + 权限检测 + ActivityResult）
            └── FxInstallFileProvider.kt  # 自定义 FileProvider
```

Kotlin 实现要点：
- 自带 FileProvider（authority: `${applicationId}.fxInstallFileProvider`），使用方无需配置
- 实现 ActivityAware，持有 Activity 引用用于 startActivityForResult
- 自动检测 `canRequestPackageInstalls`，无权限时跳系统设置页
- 用户授权后通过 ActivityResult 回调自动继续安装
- 返回结构化结果 `{isSuccess, errorMessage}`
- 兼容 Android 6.0+（≤ M 时复制到 Downloads 目录）

---

## 任务 10：AppChannel 渠道标识 `✅ 已完成`

文件：`client/modules/flash_shared/lib/src/channel.dart`

```dart
class AppChannel {
  static const String value = String.fromEnvironment('CHANNEL', defaultValue: 'standard');
  static bool get isGoogle => value == 'google';
  static bool get isStandard => value == 'standard';
}
```

在 `flash_shared.dart` 中导出。

---

## 任务 11：主项目集成（UpdateTrigger）`✅ 已完成`

文件：`client/lib/src/update/update_trigger.dart`

依赖：dio, crypto, flash_shared, fx_updater, fx_install_android, url_launcher, path_provider, package_info_plus

### 核心逻辑

| 方法 | 职责 |
|------|------|
| `checkAndPrompt(context)` | 获取版本 → FxUpdater.check → 弹窗 |
| `shouldDownload()` | 判断是否走下载流程（Google/iOS/macOS 不下载） |
| `executeUpdate(info)` | 跳转商店（_getStoreUrl + launchUrl） |
| `downloadFile(info, onProgress)` | dio 下载 + 流式 SHA256 校验 |
| `installFile(filePath)` | Android: FxInstall.apk / 其他: launchUrl(file) |
| `_fetchFromServer()` | 调 GET /api/app/version |
| `_getStoreUrl()` | 返回对应平台的商店链接 |

### 预定义商店链接

```dart
static const String _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.toly1994.flash_im';
static const String _appStoreUrl =
    'https://apps.apple.com/app/id6772819751';
```

### SHA256 校验流程

```dart
// 流式计算，不一次性加载到内存
final Digest fileDigest = await sha256.bind(file.openRead()).first;
final String fileHash = fileDigest.toString();
if (fileHash != info.sha256) {
  await file.delete();
  throw Exception('SHA256 校验失败');
}
```

---

## 任务 12：Android Flavor 配置 `✅ 已完成`

详见 [TODO_android_flavor.md](../TODO_android_flavor.md)

| 项目 | 文件 | 状态 |
|------|------|------|
| Gradle flavorDimensions | `build.gradle.kts` | ✅ |
| standard Manifest（安装权限） | `src/standard/AndroidManifest.xml` | ✅ |
| google Manifest（tools:remove） | `src/google/AndroidManifest.xml` | ✅ |
| fx_install_android 自带 FileProvider | Plugin 内部处理 | ✅ |

---

## 任务 13：构建脚本适配 `✅ 已完成`

### build_android.py

- 默认 flavor: standard，`--aab` 时自动切换 google
- `--flavor` 参数可手动覆盖
- 自动注入 `--dart-define=CHANNEL={flavor}`
- 产物路径适配 flavor 命名
- 构建后自动调用 `calculate.py` 生成 meta.json（sha256 + file_size）

### windows/build.py

- 新增 `--port` 代理参数（解决 native assets 下载失败）
- 新增 `--pack-only` 仅打包不重新构建
- flutter clean + pub get + build -v
- 构建后自动调用 `calculate.py`
- Inno Setup 打包（输出 flash-im.exe）

### build_linux.sh

- 构建后自动调用 `calculate.py`

### upload/update.py

- 读 meta.json → scp 上传产物 → POST 创建版本记录
- 自动校验版本号递增

---

## 任务 14：发布到 pub `✅ 已完成`

| 包 | pub 地址 | 版本 | 许可证 |
|---|---|---|---|
| fx_updater | https://pub.dev/packages/fx_updater | 0.1.0 | Apache 2.0 |
| fx_install_android | https://pub.dev/packages/fx_install_android | 0.1.0 | Apache 2.0 |

发布前完成：
- ✅ LICENSE（Apache 2.0）
- ✅ README.md（中文）
- ✅ CHANGELOG.md（中文）
- ✅ homepage 字段

---

## 验证清单 `✅`

| 验证项 | 状态 |
|--------|------|
| flutter pub get 无错误 | ✅ |
| flutter analyze 无诊断错误 | ✅ |
| fx_install_android 注册正确 | ✅ |
| Android standard：检测 → 下载 → 校验 → 安装 | ✅ 真机验证通过 |
| Android google：检测 → 跳转 Play Store | ✅ |
| iOS：检测 → 跳转 App Store | ✅ |
| macOS：检测 → 跳转 App Store | ✅ |
| Windows：检测 → 下载 → 打开文件 | ✅ 真机验证通过 |
| 强制更新弹窗无"稍后"按钮 | ✅ |
| SHA256 校验失败时弹窗显示错误 | ✅ |
| 设置页红点 + 手动触发更新 | ✅ |
| Web 端不触发检测 | ✅ |
| dart pub publish fx_updater | ✅ |
| dart pub publish fx_install_android | ✅ |
