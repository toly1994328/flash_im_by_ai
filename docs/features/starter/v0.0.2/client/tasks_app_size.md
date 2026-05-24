# APK 体积优化 — 客户端任务清单

基于 APK 瘦身指南，列出具体的优化改动步骤。

全局约束：
- 优化后必须在真机上完整测试（R8 可能误删反射类）
- 构建命令统一使用 `--split-per-abi --target-platform android-arm64,android-arm`
- 混淆后的 debug-info 保留在 `build/debug-info/`，不提交 git

---

## 执行顺序

1. ✅ 任务 1 — packaging 压缩 .so 和 dex（28 MB → 14.3 MB）
2. ✅ 任务 2 — 开启 R8 代码压缩 + 资源压缩
3. ✅ 任务 3 — 创建 ProGuard 规则文件
4. ✅ 任务 4 — 构建脚本增加混淆参数
5. ✅ 任务 5 — 清理未使用的依赖
6. ⬜ 任务 6 — 验证

---

## 任务 1：build.gradle.kts — packaging 压缩 `✅ 已完成`

文件：`client/android/app/build.gradle.kts`（修改）

### 1.1 添加 packaging 配置 `✅`

AGP 8+ 默认不压缩 .so 和 dex 文件（为了配合 AAB 动态分发），导致 APK 体积翻倍。
添加 `useLegacyPackaging = true` 恢复压缩行为：

```kotlin
android {
    packaging {
        dex {
            useLegacyPackaging = true
        }
        jniLibs {
            useLegacyPackaging = true
        }
    }
}
```

效果：28.0 MB → 14.3 MB，减少约 49%。

参考：[juejin.cn/post/7330471268033478666](https://juejin.cn/post/7330471268033478666)

---

## 任务 2：build.gradle.kts — 开启 R8 压缩 `✅ 已完成`

文件：`client/android/app/build.gradle.kts`（修改）

### 2.1 release buildType 添加压缩配置 `✅`

在 `buildTypes.release` 块中添加 `isMinifyEnabled` 和 `isShrinkResources`：

```kotlin
buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
        signingConfig = if (keystorePropertiesFile.exists()) {
            signingConfigs.getByName("release")
        } else {
            signingConfigs.getByName("debug")
        }
    }
}
```

说明：
- `isMinifyEnabled = true`：启用 R8 代码压缩，移除未使用的 Java/Kotlin 代码
- `isShrinkResources = true`：移除未引用的 Android 原生资源（drawable、layout 等）
- 预估效果：APK 减小 10~15%

---

## 任务 3：proguard-rules.pro — ProGuard 规则 `✅ 已完成`

文件：`client/android/app/proguard-rules.pro`（新建）

### 3.1 Flutter 核心保留规则 `✅`

```proguard
## Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

## Dart 原生通道
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

## 保留 WebView 相关（webview_flutter 插件）
-keep class android.webkit.** { *; }
-keep class io.flutter.plugins.webviewflutter.** { *; }

## 保留 SharedPreferences 插件
-keep class io.flutter.plugins.sharedpreferences.** { *; }

## 保留 SQLite 相关（drift/sqlite3）
-keep class io.requery.android.database.** { *; }
-dontwarn io.requery.android.database.**
```

### 3.2 通用安全规则 `✅`

```proguard
## 保留注解
-keepattributes *Annotation*

## 保留枚举
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

## 保留 Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
```

---

## 任务 4：构建脚本增加混淆参数 `✅ 已完成`

文件：`scripts/build_center/build_android.py`（修改）

### 4.1 APK 构建命令添加 --obfuscate `✅`

将构建命令从：

```python
cmd = f"flutter build apk --release --target-platform {target_platforms} --split-per-abi {dart_defines}"
```

改为：

```python
cmd = (
    f"flutter build apk --release"
    f" --target-platform {target_platforms}"
    f" --split-per-abi"
    f" --obfuscate --split-debug-info=build/debug-info"
    f" {dart_defines}"
)
```

### 4.2 AAB 构建命令同步添加 `✅`

```python
run(f"flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info {dart_defines}")
```

### 4.3 .gitignore 排除 debug-info `✅`

文件：`client/.gitignore`（修改）

添加：

```
build/debug-info/
```

---

## 任务 5：清理未使用的依赖 `✅ 已完成`

### 5.1 审查 pubspec.yaml `✅`

运行 `flutter pub deps --style=compact`，检查是否有未使用的插件。

重点关注体积大户：
- 确认 `webview_flutter` 是否仍需要（PolicyPage 在用 → 保留）
- 确认 `flutter_svg` 是否仍需要（登录页 GitHub 图标 → 保留）
- 检查是否有开发阶段引入但已不再使用的包

### 5.2 移除确认不用的依赖 `✅`

从 `pubspec.yaml` 中删除，运行 `flutter pub get` 确认无报错。

> 审查结果：当前所有依赖均在使用中，无需移除。

---

## 任务 6：验证 `⬜ 待处理`

### 6.1 构建对比 `⬜`

分别记录优化前后的 APK 体积：

```bash
# 优化前（当前）
flutter build apk --release --target-platform android-arm64 --split-per-abi

# 优化后
flutter build apk --release --target-platform android-arm64,android-arm --split-per-abi --obfuscate --split-debug-info=build/debug-info
```

记录 arm64 APK 的体积变化。

### 6.2 真机功能测试 `⬜`

R8 + 混淆后必须验证：
- [ ] 应用正常启动，隐私弹窗显示
- [ ] 登录流程正常（短信 + GitHub）
- [ ] 聊天收发消息正常
- [ ] WebView 页面（用户协议/隐私政策）正常加载
- [ ] 设置页各功能正常
- [ ] 语音消息录制/播放正常

### 6.3 崩溃堆栈还原测试 `⬜`

确认混淆后的崩溃日志可以用 debug-info 还原：

```bash
flutter symbolize -i crash_log.txt -d build/debug-info/
```
