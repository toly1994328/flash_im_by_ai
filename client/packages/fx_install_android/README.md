# fx_install_android

轻量级 Android APK 安装 Plugin。自带 FileProvider，无需额外配置即可使用。

## 使用

```dart
import 'package:fx_install_android/fx_install_android.dart';

await InstallPlugin.installApk('/path/to/your.apk');
```

## 权限配置

本插件需要 `REQUEST_INSTALL_PACKAGES` 权限才能调起系统安装界面。请在你的 App 的 `AndroidManifest.xml` 中声明：

```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
```

如果你的 App 有多渠道（如 Google Play 渠道不允许应用内安装），可以在对应渠道的 Manifest 中移除该权限：

```xml
<uses-permission
    android:name="android.permission.REQUEST_INSTALL_PACKAGES"
    tools:node="remove" />
```

## 工作原理

- Android 7.0+：通过插件自带的 `FxInstallFileProvider` 生成 `content://` URI，调起系统安装器
- Android 6.0 及以下：直接使用 `file://` URI

插件使用独立的 FileProvider authority（`${applicationId}.fxInstallFileProvider`），不会与你项目中已有的 FileProvider 冲突。
