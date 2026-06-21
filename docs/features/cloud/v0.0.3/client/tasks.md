# 云空间 OSS 直传 + 订阅兑换 — 前端任务清单

基于 client/design.md，拆解为可逐条执行的任务。

全局约束：
- 订阅状态放 SubscriptionCubit（flash_session 模块），全局可用
- OSS PUT 用 dio，不引入新 SDK
- 缩略图用 OSS 图片处理参数（`?x-oss-process=image/resize,w_400`），不前端生成
- VIP 头像框通过 isVip 参数控制，AvatarWidget 最小改动

---

## 执行顺序

1. ⬜ 任务 1 — SubscriptionRepository 数据层（无依赖）
2. ⬜ 任务 2 — SubscriptionCubit 状态管理（依赖任务 1）
3. ⬜ 任务 3 — OssUploader 直传封装（无依赖）
4. ⬜ 任务 4 — ChatFileMixin 上传分流（依赖任务 2、3）
5. ⬜ 任务 5 — 兑换码页面（依赖任务 2）
6. ⬜ 任务 6 — VIP 头像框（依赖任务 2）
7. ⬜ 任务 7 — HomePage 初始化订阅状态（依赖任务 2）
8. ⬜ 任务 8 — 编译验证

---

## 任务 1：SubscriptionRepository `⬜ 待处理`

文件：`client/modules/flash_session/lib/src/data/subscription_repository.dart`（新建）

### 1.1 创建文件 `⬜`

```dart
import 'package:dio/dio.dart';

class SubscriptionStatus {
  final bool hasActiveSubscription;
  final String? planCode;
  final String? planName;
  final DateTime? expiresAt;
  final bool ossUploadEnabled;
  final int usedBytes;
  final int quotaBytes;

  // fromJson 构造
}

class RedeemResult {
  final String planCode;
  final String planName;
  final DateTime expiresAt;
  final int storageBytes;
  final int usedBytes;
  final int quotaBytes;

  // fromJson 构造
}

class SubscriptionRepository {
  final Dio _dio;

  SubscriptionRepository({required Dio dio}) : _dio = dio;

  /// GET /api/subscriptions/status
  Future<SubscriptionStatus> getStatus() async { ... }

  /// POST /api/subscriptions/redeem
  Future<RedeemResult> redeem(String code) async { ... }
}
```

### 1.2 导出 `⬜`

在 `flash_session` 的 barrel file 中导出 SubscriptionRepository 和相关类型。

---

## 任务 2：SubscriptionCubit `⬜ 待处理`

文件：`client/modules/flash_session/lib/src/logic/subscription_cubit.dart`（新建）

### 2.1 创建 Cubit `⬜`

```dart
class SubscriptionCubit extends Cubit<SubscriptionStatus> {
  final SubscriptionRepository _repository;

  SubscriptionCubit({required SubscriptionRepository repository})
      : _repository = repository,
        super(const SubscriptionStatus.empty());

  /// 登录后调用，查询订阅状态
  Future<void> loadStatus() async { ... }

  /// 兑换码激活后刷新
  Future<RedeemResult> redeem(String code) async { ... }

  /// 是否可以走 OSS 上传
  bool get ossUploadEnabled => state.ossUploadEnabled;
}
```

### 2.2 注册到 Provider 树 `⬜`

在 `main.dart` 中 RepositoryProvider 旁边创建 SubscriptionRepository，
BlocProvider 中创建 SubscriptionCubit。

---

## 任务 3：OssUploader `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/data/oss_uploader.dart`（新建）

### 3.1 创建文件 `⬜`

```dart
import 'dart:io';
import 'package:dio/dio.dart';

class OssUploadToken { ... } // fromJson

class OssUploadResult {
  final int fileId;
  final String url;
  final String? thumbUrl;
}

class OssUploader {
  final Dio _dio;

  OssUploader({required Dio dio}) : _dio = dio;

  /// 完整上传流程：获取 token → PUT OSS → confirm
  Future<OssUploadResult> upload({
    required String filePath,
    required String fileName,
    required int fileSize,
    required String mimeType,
    required String hash,
    String? mimeCategory,
    int? width,
    int? height,
    int? durationMs,
    void Function(double)? onProgress,
  }) async {
    // 1. POST /api/storage/upload-token
    // 2. PUT 文件到 OSS（用 STS Token 签名）
    // 3. POST /api/storage/confirm-upload
    // 4. 返回 OssUploadResult
  }
}
```

### 3.2 OSS PUT 签名 `⬜`

dio PUT 请求到 OSS，需要在 headers 中携带：
- `x-oss-security-token`: securityToken
- `Authorization`: 使用临时 AK/SK 签名（或用 presigned URL 方式）

实际上直接用 presigned URL 更简单——但 upload-token 接口返回的是 STS 凭证。
方案：前端用 STS 凭证构造 `Authorization` header（OSS V4 签名），或者改后端返回 presigned URL。

**简化方案**：后端 `upload-token` 接口改为直接返回 presigned PUT URL，前端 dio.put(url, data) 就行，不需要前端签名。

---

## 任务 4：ChatFileMixin 上传分流 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_file_mixin.dart`（修改）

### 4.1 注入 OssUploader + SubscriptionCubit `⬜`

ChatCubit 构造函数增加可选参数：

```dart
final OssUploader? ossUploader;
final SubscriptionCubit? subscriptionCubit;
```

### 4.2 sendImageFromFile 分流 `⬜`

在现有 `sendImageFromFile` 的上传阶段增加判断：

```dart
if (subscriptionCubit?.ossUploadEnabled == true && ossUploader != null) {
  // OSS 直传
  final OssUploadResult result = await ossUploader!.upload(
    filePath: filePath, fileName: ..., fileSize: ...,
    mimeType: 'image/...', hash: hash, mimeCategory: 'image',
    width: imgWidth, height: imgHeight, onProgress: ...
  );
  // result.url 以 https:// 开头
} else {
  // 现有 multipart 上传（不变）
  final result = await repository.uploadImage(filePath, hash: hash, onProgress: ...);
}
```

### 4.3 sendVideoFromFile / sendFileFromFile 同理 `⬜`

同样的分流逻辑。

### 4.4 403 Fallback `⬜`

OSS 上传路径中，如果 upload-token 返回 403：
```dart
try {
  result = await ossUploader!.upload(...);
} on DioException catch (e) {
  if (e.response?.statusCode == 403) {
    subscriptionCubit?.loadStatus(); // 刷新状态
    result = await _fallbackLocalUpload(...); // 降级本地
  } else { rethrow; }
}
```

---

## 任务 5：兑换码页面 `⬜ 待处理`

文件：`client/lib/src/home/profile/redeem_page.dart`（新建）

### 5.1 UI 结构 `⬜`

```
Scaffold
├── AppBar: "兑换码"
└── body: Padding
    ├── TextField（兑换码输入）
    ├── SizedBox(h: 16)
    ├── ElevatedButton("兑换")
    └── 结果提示（成功/失败）
```

### 5.2 兑换逻辑 `⬜`

```dart
onPressed: () async {
  final result = await context.read<SubscriptionCubit>().redeem(code);
  // 成功：显示 "已激活 {planName}，到期 {expiresAt}"
  // 失败：显示错误消息
}
```

### 5.3 入口 `⬜`

在 ProfilePage 或云空间设置页增加"兑换码"入口行。

---

## 任务 6：VIP 头像框 `⬜ 待处理`

文件：`client/modules/flash_shared/lib/src/widgets/avatar_widget.dart`（修改）

### 6.1 增加 isVip 参数 `⬜`

```dart
class AvatarWidget extends StatelessWidget {
  final String? avatar;
  final double size;
  final double borderRadius;
  final bool isVip;  // 新增，默认 false
  ...
}
```

### 6.2 VIP 时加渐变边框 `⬜`

```dart
if (isVip) {
  return Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius + 2),
      gradient: const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
      ),
    ),
    child: _buildAvatar(),
  );
}
return _buildAvatar();
```

---

## 任务 7：HomePage 初始化订阅状态 `⬜ 待处理`

文件：`client/lib/src/home/view/home_page.dart`（修改）

### 7.1 initState 中加载订阅状态 `⬜`

```dart
@override
void initState() {
  super.initState();
  ...
  context.read<SubscriptionCubit>().loadStatus();
}
```

---

## 任务 8：编译验证 `⬜ 待处理`

### 8.1 flutter analyze `⬜`

```bash
cd client && flutter analyze
```

### 8.2 手动验证 `⬜`

- [ ] 无订阅用户上传图片走本地（日志确认）
- [ ] 输入兑换码 TEST-PRO-2026 激活成功
- [ ] 激活后上传图片走 OSS（日志 + OSS 控制台确认）
- [ ] VIP 头像框显示
- [ ] 消息中 OSS URL 图片正常展示
