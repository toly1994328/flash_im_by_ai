# Android 发布准备 — 客户端任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。

全局约束：
- key.properties 不提交 git
- 协议 URL 使用 AppConfig 中的 baseUrl 拼接

---

## 执行顺序

1. ✅ 任务 1 — 静态 HTML 协议文件
2. ✅ 任务 2 — policy_page.dart 通用协议页面
3. ✅ 任务 3 — agreement_row.dart 修改链接跳转
4. ✅ 任务 4 — 应用名称改为"闪讯" + 图标生成（flutter_launcher_icons）
5. ✅ 任务 5 — 签名配置（keystore + key.properties + build.gradle.kts）
6. ✅ 任务 6 — 构建脚本
7. ✅ 任务 7 — .gitignore 更新
8. ✅ 任务 8 — 设置页面（微信风格分组列表：账号/关于/退出）
9. ✅ 任务 9 — 关于闪讯独立页面（logo + 版本 + 简介 + 版权）
10. ✅ 任务 10 — 我的名片页面（二维码 + 个性签名 + 中心 logo）
11. ✅ 任务 11 — 登录页底部优化（GitHub + 密码登录并排）
12. ✅ 任务 12 — 注销账号（弹窗警告 + 邮件注销流程）
13. ⬜ 任务 13 — 首次启动隐私协议弹窗
14. ⬜ 任务 14 — 验证

---

## 任务 13：首次启动隐私协议弹窗 `⬜ 待处理`

### 13.1 privacy_consent_dialog.dart 弹窗组件 `⬜`

文件：`client/modules/flash_starter/lib/src/privacy_consent_dialog.dart`（新建）

```dart
class PrivacyConsentDialog extends StatelessWidget {
  final VoidCallback onAgree;
  final VoidCallback onDisagree;
  final String baseUrl;  // 用于拼接协议链接
}
```

弹窗内容：
- 标题："服务协议和隐私政策"
- 正文：简要说明（"欢迎使用闪讯！在使用前，请您阅读并同意以下协议："）
- 协议链接：蓝色可点击的《用户协议》和《隐私政策》，点击跳转 PolicyPage
- 底部按钮：
  - "同意并继续"（品牌蓝填充按钮）
  - "不同意"（灰色文字按钮）
- 点击"不同意"弹出二次确认："不同意将无法使用闪讯，确定退出吗？"
  - 确定 → `SystemNavigator.pop()` 退出应用
  - 取消 → 回到弹窗

### 13.2 splash_page.dart 修改 `⬜`

在启动任务完成后、调用 `onComplete` 前，检查 SharedPreferences 中 `privacy_agreed` 是否为 true：
- 已同意 → 正常走 onComplete
- 未同意 → 显示 PrivacyConsentDialog，用户点同意后写入 `privacy_agreed = true`，再走 onComplete

### 13.3 导出 `⬜`

`flash_starter/lib/flash_starter.dart` 导出 `PrivacyConsentDialog`（供外部自定义使用）。

---

## 任务 1：静态 HTML 协议文件 `✅ 已完成`

文件：`server/static/agreement.html` + `server/static/privacy.html`（新建）

### 1.1 用户协议 `✅`

移动端友好的 HTML 页面，包含服务说明、账号注册、使用规范、知识产权、免责声明等。

### 1.2 隐私政策 `✅`

包含信息收集表格、使用目的、存储安全、权限说明、未成年人保护等。

---

## 任务 4：应用名称 + 图标 `✅ 已完成`

### 4.1 修改应用名称 `✅`

文件：`client/android/app/src/main/AndroidManifest.xml`

将 `android:label` 从 `flash_im` 改为 `闪讯`：

```xml
<application android:label="闪讯" ...>
```

### 4.2 更新应用图标 `✅`

**步骤 1**：准备一张 512×512 以上的 logo 图片，放到 `client/assets/images/logo.png`

**步骤 2**：在 `client/pubspec.yaml` 的 `dev_dependencies` 中添加：

```yaml
flutter_launcher_icons: ^0.14.0
```

并在 pubspec.yaml 末尾添加配置：

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo.png"
```

**步骤 3**：运行生成命令：

```bash
cd client
flutter pub get
dart run flutter_launcher_icons
```

它会自动从 logo.png 生成 Android（mipmap-hdpi ~ xxxhdpi）和 iOS 所有尺寸的图标并替换到对应目录。

---

## 任务 2：policy_page.dart — 通用协议页面 `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/view/policy_page.dart`（新建）

### 2.1 PolicyPage Widget `⬜`

```dart
class PolicyPage extends StatefulWidget {
  final String title;  // "用户协议" 或 "隐私政策"
  final String url;    // 完整 URL

  const PolicyPage({super.key, required this.title, required this.url});
}
```

### 2.2 实现 `⬜`

- AppBar：白色背景，标题居中，左侧返回按钮
- Body：WebViewWidget 加载 url
- Loading：页面加载中显示 CircularProgressIndicator

---

## 任务 3：agreement_row.dart — 链接跳转 `⬜ 待处理`

文件：`client/modules/flash_auth/lib/src/view/components/agreement_row.dart`（修改）

### 3.1 将协议文字改为可点击 `⬜`

当前"《用户协议》"和"《隐私政策》"是纯文本。改为 GestureDetector 包裹的蓝色文字，点击后：

```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => PolicyPage(
    title: '用户协议',
    url: '${AppConfig.baseUrl}/static/agreement.html',
  ),
));
```

隐私政策同理，url 改为 `/static/privacy.html`。

---

## 任务 4：签名配置 `⬜ 待处理`

### 4.1 生成 keystore `⬜`

```bash
keytool -genkey -v -keystore flash-im-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias flash-im
```

将生成的 `flash-im-release.jks` 放到 `client/android/` 目录。

### 4.2 创建 key.properties `⬜`

文件：`client/android/key.properties`（新建，不提交 git）

```properties
storePassword=你的密码
keyPassword=你的密码
keyAlias=flash-im
storeFile=../flash-im-release.jks
```

### 4.3 修改 build.gradle.kts `⬜`

文件：`client/android/app/build.gradle.kts`（修改）

在 `android {}` 块内添加签名配置：

```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

---

## 任务 5：构建脚本 `⬜ 待处理`

文件：`scripts/client/build_apk.py`（新建）

### 5.1 功能 `⬜`

```python
# 用法：
#   python scripts/client/build_apk.py          # 构建 APK
#   python scripts/client/build_apk.py --aab    # 构建 AAB
#   python scripts/client/build_apk.py --upload root@IP  # 构建并上传到服务器

# 流程：
# 1. cd client
# 2. flutter clean（可选，加 --clean 参数）
# 3. flutter pub get
# 4. flutter build apk --release（或 appbundle）
# 5. 输出文件路径和大小
# 6. 可选：scp 上传到服务器 /static/ 目录
```

---

## 任务 6：.gitignore 更新 `⬜ 待处理`

文件：`client/android/.gitignore`（修改）

### 6.1 添加 `⬜`

```
key.properties
*.jks
```

---

## 任务 7：验证 `⬜ 待处理`

### 7.1 协议页面 `⬜`

- 启动后端，确认 `http://localhost:9600/static/agreement.html` 可访问
- 启动客户端，点击用户协议/隐私政策链接，WebView 正常显示

### 7.2 签名构建 `⬜`

```bash
cd client
flutter build apk --release
```

确认输出的 APK 使用 release 签名（非 debug）。

### 7.3 AAB 构建 `⬜`

```bash
flutter build appbundle --release
```

确认生成 `build/app/outputs/bundle/release/app-release.aab`。
