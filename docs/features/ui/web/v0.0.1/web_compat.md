# Flutter Web 兼容适配记录

## 概述

将闪讯从原生平台（Android/iOS/macOS/Windows/Linux）扩展到 Web 端。核心挑战是处理 `dart:io` 和 `dart:ffi` 在 Web 端不可用的问题。

---

## 一、本地数据库（drift）

### 问题

原来的 `AppDatabase` 使用 `drift/native.dart` 的 `NativeDatabase`，依赖 `dart:ffi` 加载原生 SQLite 二进制。Web 端不支持 `dart:ffi`，编译直接报错。

### 解决方案

使用 `drift_flutter` 包的 `driftDatabase` 函数，它内部自动处理平台差异：
- 原生平台：使用 `NativeDatabase`（通过 `sqlite3_flutter_libs`）
- Web 平台：使用 `WasmDatabase`（通过 `sqlite3.wasm` WebAssembly）

### 改动

**文件**：`client/modules/flash_im_cache/lib/src/drift/database/app_database.dart`

```dart
// 改动前
import 'dart:io';
import 'package:drift/native.dart';

static Future<AppDatabase> open(int userId) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'im_cache_$userId.db'));
  return AppDatabase(NativeDatabase.createInBackground(file));
}

// 改动后
import 'package:drift_flutter/drift_flutter.dart';

static Future<AppDatabase> open(int userId) async {
  return AppDatabase(
    driftDatabase(
      name: 'im_cache_$userId',
      native: DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );
}
```

**依赖变更**：`flash_im_cache/pubspec.yaml`

```yaml
# 改动前
drift: ^2.25.0
sqlite3_flutter_libs: ^0.5.28

# 改动后
drift: ^2.25.0
drift_flutter: 0.3.0
sqlite3: 3.3.2
sqlite3_flutter_libs: ^0.6.0
```

**Web 资源**：`client/web/sqlite3.wasm`（从 https://github.com/niclas-niclas/niclas-niclas.github.io/raw/main/sqlite3.wasm 下载，需与 sqlite3 3.3.2 版本匹配。实际来源：https://github.com/simolus3/drift/blob/develop/extras/assets/sqlite3.wasm）

---

## 二、平台判断（Platform.isXxx）

### 问题

`dart:io` 的 `Platform` 类在 Web 端不可用。直接调用 `Platform.isWindows` 等会抛出运行时异常。

### 解决方案

使用 `fx_env` 包的 `kApp` 全局对象，它在初始化时通过 `kIsWeb` 前置判断，Web 端安全返回 false。

### 改动清单

| 文件 | 原代码 | 改为 |
|------|--------|------|
| `app.dart` | `Platform.isWindows` | `kApp.isWindows` |
| `login_page.dart` | `Platform.isWindows \|\| Platform.isMacOS \|\| Platform.isLinux` | `kApp.isDesktop` |
| `login_page.dart` | `!Platform.isIOS` | `!kApp.isIos` |
| `desktop_login_body.dart` | `Platform.isWindows` | `kApp.isWindows` |
| `other_login_row.dart` | `Platform.isIOS \|\| Platform.isMacOS` | `kApp.isIos \|\| kApp.isMacOS` |
| `device_info.dart` | 多处 `Platform.isXxx` | `kIsWeb` 前置判断包裹 |

### kApp 的 API

```dart
kApp.isAndroid   // bool
kApp.isIos       // bool（注意小写 o）
kApp.isWindows   // bool
kApp.isMacOS     // bool
kApp.isLinux     // bool
kApp.isWeb       // bool
kApp.isDesktop   // bool（Windows/macOS/Linux）
kApp.isMobile    // bool（Android/iOS）
```

Web 端所有平台判断都返回 false，`kApp.isWeb` 返回 true。

---

## 三、设备信息采集（device_info.dart）

### 问题

`DeviceInfoPlugin` 在 Web 端需要用 `webBrowserInfo` 而不是 `androidInfo`/`iosInfo` 等。

### 解决方案

加 `kIsWeb` 前置判断，Web 端走 `deviceInfoPlugin.webBrowserInfo`：

```dart
if (!kIsWeb) {
  if (Platform.isAndroid) { ... }
  else if (Platform.isIOS) { ... }
  // ...
  platform = Platform.operatingSystem;
} else {
  final info = await deviceInfoPlugin.webBrowserInfo;
  deviceName = info.browserName.name;
  platform = 'web';
}
```

---

## 四、窗口管理（window_manager）

### 当前状态

`main.dart` 中 `window_manager` 的调用被 `kApp.isDesktop` 保护，Web 端不会执行。暂时不需要额外处理。

### 后续优化

如果 Web 端构建时不想打包 `window_manager` 的代码，可以用条件导入隔离。当前不影响编译和运行。

---

## 五、已知的 Web 端限制

| 功能 | 状态 | 说明 |
|------|------|------|
| 本地数据库 | ✅ 可用 | drift + sqlite3.wasm（WebAssembly SQLite，数据存储在 IndexedDB/OPFS） |
| WebSocket | ✅ 可用 | 浏览器原生 WebSocket |
| 文件上传 | ⚠️ 需适配 | Web 端 file_picker 返回 bytes 而非 path |
| 语音录制 | ⚠️ 需适配 | record_web 包支持，但 API 不同 |
| 视频播放 | ⚠️ 需适配 | 需要用 HTML5 video 或 video_player_web |
| 扫码 | ❌ 不支持 | mobile_scanner 不支持 Web |
| 窗口管理 | ❌ 不适用 | Web 端无窗口概念 |
| 系统通知 | ⚠️ 需适配 | 需要用 Web Notification API |

---

## 六、构建命令

```bash
# 开发模式
flutter run -d chrome --dart-define-from-file=.env.dev

# 生产构建
flutter build web --release --dart-define-from-file=.env.production

# 产物目录
client/build/web/
```
