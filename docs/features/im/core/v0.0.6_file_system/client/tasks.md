# 云资源管理 — 客户端任务清单

基于 client/design.md 设计，列出需要创建/修改的具体细节。

全局约束：
- 状态管理使用 Cubit，不使用 Event 模式
- 变量显式标注类型，禁止 `var`
- 日志使用 `FxLog`，不使用 `print`
- 大文件 SHA-1 在 Isolate 中计算，避免卡 UI

---

## 执行顺序

1. ✅ 任务 1 — 添加 crypto 依赖
2. ✅ 任务 2 — file_hash.dart（SHA-1 计算工具）
3. ✅ 任务 3 — MessageRepository 上传方法加 hash 参数 + checkHash(hash, size) 接口
4. ✅ 任务 4 — ChatFileMixin：`_preUploadCheck` 公共预检方法（hash + 秒传 + 配额），所有 send 方法在占位消息之前调用
5. ✅ 任务 5 — StorageRepository（配额查询接口）
6. ✅ 任务 6 — StorageQuotaCubit（状态管理 + 监听 WS 通知实时刷新）
7. ✅ 任务 7 — CloudStorageCard（"我的"页云空间卡片，蓝/黄/红/绿分色进度条）
8. ✅ 任务 8 — CloudStoragePage（云空间详情页，圆环图 + 分类列表）
9. ✅ 任务 9 — ProfilePage 插入云空间卡片（注入 WsClient）
10. ✅ 任务 10 — 配额不足错误处理（DioException 403 QUOTA_EXCEEDED，在占位消息前拦截）
11. ✅ 任务 11 — 编译验证（flutter analyze: 0 errors）
12. ✅ 任务 12 — WS proto 枚举扩展（STORAGE_QUOTA_UPDATE = 18）
13. ✅ 任务 13 — WsClient 新增 storageQuotaStream

---

## 任务 1：添加 crypto 依赖 `⬜ 待处理`

文件：`client/modules/flash_im_chat/pubspec.yaml`（修改）

### 1.1 添加 crypto 包 `⬜`

在 dependencies 中添加：

```yaml
  crypto: ^3.0.6
```

---

## 任务 2：file_hash.dart `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/data/file_hash.dart`（新建）

### 2.1 实现 computeFileSha1 `⬜`

```dart
import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';

/// 在 Isolate 中计算文件 SHA-1（避免大文件卡 UI）
Future<String> computeFileSha1(String filePath) async {
  return await Isolate.run(() {
    final List<int> bytes = File(filePath).readAsBytesSync();
    return sha1.convert(bytes).toString();
  });
}
```

---

## 任务 3：MessageRepository 上传方法加 hash `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/data/message_repository.dart`（修改）
文件：`client/modules/flash_im_chat/lib/src/data/i_message_repository.dart`（修改）

### 3.1 IMessageRepository 接口添加 hash 参数 `⬜`

```dart
Future<ImageUploadResult> uploadImage(String filePath, {required String hash, void Function(double)? onProgress});
Future<VideoUploadResult> uploadVideo(String filePath, String thumbPath, int durationMs, {required String hash, int width, int height, void Function(double)? onProgress});
Future<FileUploadResult> uploadFile(String filePath, {required String hash, void Function(double)? onProgress});
```

### 3.2 MessageRepository 实现传 hash `⬜`

在 `uploadImage` 的 FormData 中添加 hash 字段：

```dart
final FormData formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(filePath, filename: fileName),
  'hash': hash,
});
```

uploadVideo 同理：

```dart
final FormData formData = FormData.fromMap({
  'video': await MultipartFile.fromFile(videoPath),
  'thumbnail': await MultipartFile.fromFile(thumbnailPath),
  'hash': hash,
  'duration_ms': durationMs.toString(),
  'width': width.toString(),
  'height': height.toString(),
});
```

uploadFile 同理：

```dart
final FormData formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(filePath, filename: fileName),
  'hash': hash,
});
```

### 3.3 响应新增 is_dedup 和 file_id 字段 `⬜`

ImageUploadResult / VideoUploadResult / FileUploadResult 各新增：

```dart
final int fileId;
final bool isDedup;
```

从 JSON 解析时读取 `file_id` 和 `is_dedup`。

---

## 任务 4：ChatFileMixin 调用时传入 hash `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_file_mixin.dart`（修改）

### 4.1 导入 file_hash.dart `⬜`

```dart
import '../data/file_hash.dart';
```

### 4.2 sendImageFromFile 中计算 hash `⬜`

在上传前（`repository.uploadImage` 调用前）添加：

```dart
final String hash = await computeFileSha1(filePath);
```

然后传给 uploadImage：

```dart
final result = await repository.uploadImage(filePath, hash: hash, onProgress: ...);
```

### 4.3 sendVideoFromFile 中计算 hash `⬜`

```dart
final String hash = await computeFileSha1(filePath);
final result = await repository.uploadVideo(filePath, thumbnailPath, durationMs, hash: hash, ...);
```

### 4.4 sendFileFromPicker 中计算 hash `⬜`

```dart
final String hash = await computeFileSha1(filePath);
final result = await repository.uploadFile(filePath, hash: hash, onProgress: ...);
```

### 4.5 sendAudioFromFile 中计算 hash `⬜`

```dart
final String hash = await computeFileSha1(filePath);
final result = await repository.uploadFile(filePath, hash: hash, onProgress: ...);
```

---

## 任务 5：StorageRepository `⬜ 待处理`

文件：`client/lib/src/home/profile/storage_repository.dart`（新建）

### 5.1 实现配额查询 `⬜`

```dart
import 'package:dio/dio.dart';

class StorageQuota {
  final int usedBytes;
  final int quotaBytes;
  final Map<String, CategoryUsage> breakdown;

  StorageQuota({required this.usedBytes, required this.quotaBytes, required this.breakdown});

  double get usagePercent => quotaBytes > 0 ? usedBytes / quotaBytes : 0;
  String get usedFormatted => _formatBytes(usedBytes);
  String get quotaFormatted => _formatBytes(quotaBytes);
  String get remainFormatted => _formatBytes(quotaBytes - usedBytes);

  factory StorageQuota.fromJson(Map<String, dynamic> json) {
    // 解析 breakdown
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class CategoryUsage {
  final int size;
  final int count;
  CategoryUsage({required this.size, required this.count});
}

class StorageRepository {
  final Dio _dio;
  StorageRepository({required Dio dio}) : _dio = dio;

  Future<StorageQuota> getQuota() async {
    final Response<dynamic> res = await _dio.get('/api/storage/quota');
    return StorageQuota.fromJson(res.data as Map<String, dynamic>);
  }
}
```

---

## 任务 6：StorageQuotaCubit `⬜ 待处理`

文件：`client/lib/src/home/profile/storage_quota_cubit.dart`（新建）

### 6.1 实现 Cubit `⬜`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'storage_repository.dart';

enum StorageQuotaStatus { initial, loading, loaded, error }

class StorageQuotaState {
  final StorageQuotaStatus status;
  final StorageQuota? quota;
  final String? error;
  // ...
}

class StorageQuotaCubit extends Cubit<StorageQuotaState> {
  final StorageRepository _repository;

  StorageQuotaCubit({required StorageRepository repository})
    : _repository = repository,
      super(StorageQuotaState.initial());

  Future<void> loadQuota() async {
    emit(state.copyWith(status: StorageQuotaStatus.loading));
    try {
      final StorageQuota quota = await _repository.getQuota();
      emit(state.copyWith(status: StorageQuotaStatus.loaded, quota: quota));
    } catch (e) {
      emit(state.copyWith(status: StorageQuotaStatus.error, error: e.toString()));
    }
  }
}
```

---

## 任务 7：CloudStorageCard `⬜ 待处理`

文件：`client/lib/src/home/profile/cloud_storage_card.dart`（新建）

### 7.1 实现卡片组件 `⬜`

- 白底圆角卡片，内含：
  - 左侧图标（云朵）+ "云空间" 标题
  - 右侧文字 "62MB / 100MB" + 箭头
  - 底部分色进度条（图片绿/视频蓝/音频橙/文件灰）
- 接收 `StorageQuota` 参数
- 点击回调 `onTap`

进度条用 `CustomPainter` 或 `Row` + `Expanded` + 各色 `Container`。

---

## 任务 8：CloudStoragePage `⬜ 待处理`

文件：`client/lib/src/home/profile/cloud_storage_page.dart`（新建）

### 8.1 实现详情页 `⬜`

- Scaffold + AppBar "云空间"
- 顶部：圆环图（CustomPainter 画环形进度）显示总用量占比
- 中间：总量文字 "已用 62MB / 100MB"
- 下方列表：每种类型一行
  - 图标（彩色圆点）+ 类型名 + 文件数 + 大小
  - image / video / audio / file 四类

---

## 任务 9：ProfilePage 插入云空间卡片 `⬜ 待处理`

文件：`client/lib/src/home/profile/profile_page.dart`（修改）

### 9.1 在"我的名片"和"设置"之间插入 `⬜`

在现有两个 `_buildGroup` 之间添加：

```dart
const SizedBox(height: 8),
BlocProvider(
  create: (_) => StorageQuotaCubit(repository: StorageRepository(dio: ...))..loadQuota(),
  child: BlocBuilder<StorageQuotaCubit, StorageQuotaState>(
    builder: (context, state) {
      if (state.status != StorageQuotaStatus.loaded) return const SizedBox.shrink();
      return CloudStorageCard(
        quota: state.quota!,
        onTap: () => _pushPage(context, const CloudStoragePage()),
      );
    },
  ),
),
```

### 9.2 Dio 实例获取 `⬜`

从 context 中获取 Dio 实例（通过 MessageRepository.dio 或直接注入）。

---

## 任务 10：配额不足错误处理 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_file_mixin.dart`（修改）

### 10.1 捕获 QUOTA_EXCEEDED 错误 `⬜`

在各 send 方法的 catch 中判断 DioException 的响应：

```dart
} on DioException catch (e) {
  if (e.response?.statusCode == 403) {
    final Map<String, dynamic>? body = e.response?.data;
    if (body?['code'] == 'QUOTA_EXCEEDED') {
      final int used = body?['used_bytes'] ?? 0;
      final int quota = body?['quota_bytes'] ?? 0;
      ShowToastEvent('云空间不足（已用 ${_formatSize(used)} / ${_formatSize(quota)}）').emit();
      markFailed(localId);
      return;
    }
  }
  markFailed(localId);
}
```

---

## 任务 11：编译验证 `⬜ 待处理`

### 11.1 flutter analyze `⬜`

```bash
cd client && flutter analyze
```

确认 0 issues。

### 11.2 手动验证路径 `⬜`

1. 发送图片 → 控制台看到 hash 计算日志 → 上传成功 → 消息显示正常
2. 发送相同图片 → is_dedup=true → 无重复存储
3. "我的"页面 → 看到云空间卡片 → 显示用量
4. 点击卡片 → 进入详情页 → 圆环图 + 分类列表
