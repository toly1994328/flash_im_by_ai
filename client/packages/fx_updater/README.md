# fx_updater

轻量级 Flutter 应用更新框架。

提供版本检测、更新弹窗（含下载进度）、平台策略接口、全局更新状态管理。不依赖任何网络库，通过回调注入数据获取逻辑。

## 特性

- **版本比较** — 语义化版本号模型，支持比较运算符
- **更新检查器** — 通过回调注入 fetch 逻辑，不绑定 dio/http
- **更新弹窗** — Material 风格对话框，支持下载进度、重试、强制更新
- **平台策略** — Android APK 安装、桌面端打开文件、iOS/macOS 跳转商店
- **全局状态** — 单例 `FxUpdater`，通过 Stream 暴露红点、进度、状态

## 使用

```dart
import 'package:fx_updater/fx_updater.dart';

final UpdateChecker checker = UpdateChecker(
  currentVersion: AppVersion.parse('1.0.0'),
  fetchUpdateInfo: () => yourFetchFunction(),
);

final UpdateCheckResult result = await checker.check();
if (result is UpdateAvailable) {
  UpdateDialog.show(context, info: result.info);
}
```

## 结构

```
lib/src/
├── data/       # 数据模型：AppVersion、UpdateInfo、UpdateCheckResult
├── logic/      # 逻辑层：UpdateChecker、FxUpdater、UpdateStrategy
└── view/       # 视图层：UpdateDialog、UpdateBadge
```
