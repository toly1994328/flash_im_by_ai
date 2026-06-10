# 文件缓存机制 — 前端任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。

**全局约束**：
- 状态管理使用 Cubit，不使用 Event 模式
- 日志使用 `fx_logger`，禁止 `print`
- 变量声明显式标注类型
- `flash_im_cache` 放纯 Dart + dart:io 代码（不依赖 Flutter/drift，Web 平台不适用）
- `flash_im_cache_drift` 处理 drift 具体实现
- 修改 drift 表后需重新运行 `build_runner`
- 图片自动缓存在 Cubit 的 loadMessages 后触发，不在 Widget build 中发起异步

---

## 执行顺序

1. ✅ 任务 1 — CachedMessage 模型加 localData 字段
2. ✅ 任务 2 — Message 模型加 localData 字段
3. ✅ 任务 3 — LocalStore 接口加 updateLocalData / getLocalData 方法
4. ✅ 任务 4 — CachedMessagesTable 加 localData 列 + 数据库迁移
5. ✅ 任务 5 — MessageDao 加 localData 操作方法
6. ✅ 任务 6 — converters.dart 同步 localData 映射
7. ✅ 任务 7 — DriftLocalStore 实现新接口方法
8. ✅ 任务 8 — 运行 build_runner 重新生成
9. ✅ 任务 9 — FileCacheManager 抽象接口
10. ✅ 任务 10 — FileCacheManagerImpl 队列实现 + NoOpFileCacheManager
11. ✅ 任务 11 — flash_im_cache 导出新文件
12. ✅ 任务 12 — ChatFileMixin 改造：集成 FileCacheManager + FileSendLimits
13. ✅ 任务 13 — ChatCubit 注入 FileCacheManager + baseUrl + 图片/视频封面/音频自动缓存
14. ✅ 任务 14 — ImageBubble 改造：优先本地路径
15. ✅ 任务 15 — VideoBubble 改造：缩略图优先本地
16. ✅ 任务 16 — AudioBubble 改造：音频路径优先本地
17. ✅ 任务 17 — FileBubble 改造：下载完成后标记本地
18. ✅ 任务 18 — Debug 面板显示 localData 信息
19. ✅ 任务 19 — 桌面端右键菜单：另存为 + 打开文件夹
20. ✅ 任务 20 — 桌面端文件/视频点击行为改造
21. ✅ 任务 21 — 发送大小限制 + toast 提示
22. ✅ 任务 22 — main.dart 全局初始化 FileCacheManager + home_actions_mixin 注入
23. ✅ 任务 23 — 编译验证 + 手动测试通过

---

## 任务 1：cached_message.dart — 加 localData 字段 `⬜ 待处理`

文件：`client/modules/flash_im_cache/lib/src/models/cached_message.dart`

### 1.1 新增 localData 字段 `⬜`

在 `CachedMessage` 类中新增可空字段：

```dart
class CachedMessage {
  // ... 现有字段 ...
  final String? localData; // JSON: {"path": "...", "cached_at": 1718000000000}

  const CachedMessage({
    // ... 现有参数 ...
    this.localData,
  });
}
```

---

## 任务 2：message.dart — Message 模型加 localData 字段 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/data/message.dart`

### 2.1 新增 localData 字段 `⬜`

```dart
class Message {
  // ... 现有字段 ...
  final String? localData; // 本地文件缓存信息 JSON

  const Message({
    // ... 现有参数 ...
    this.localData,
  });
}
```

### 2.2 更新 copyWith `⬜`

```dart
Message copyWith({
  // ... 现有参数 ...
  String? localData,
  bool clearLocalData = false,
}) {
  return Message(
    // ...
    localData: clearLocalData ? null : (localData ?? this.localData),
  );
}
```

### 2.3 更新 message_ext.dart `⬜`

文件：`client/modules/flash_im_chat/lib/src/data/message_ext.dart`

`toCached()` 中映射 localData：

```dart
CachedMessage toCached() => CachedMessage(
  // ... 现有字段 ...
  localData: localData,
);
```

### 2.4 MessageRepository 从缓存加载时填入 localData `⬜`

文件：`client/modules/flash_im_chat/lib/src/data/message_repository.dart`

从 `CachedMessage` 转 `Message` 时，将 `cachedMessage.localData` 带入。

### 2.5 新增 pendingLocalPaths Map `⬜`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_file_mixin.dart`

发送文件时需要暂存 `localId → localPath` 映射，ack 时才能知道用哪个本地路径写 localData：

```dart
/// 暂存发送中的本地文件路径：localId → localPath
final Map<String, String> _pendingLocalPaths = {};
```

在 `sendImageFromFile` / `sendVideoFromFile` / `sendFileFromPicker` / `sendAudioFromFile` 中：
```dart
_pendingLocalPaths[localId] = filePath;
```

在 ChatCubit 的 `_handleMessageAck` 中，取出路径写入 localData：
```dart
final String? localPath = _pendingLocalPaths.remove(localId);
if (localPath != null && fileCacheManager != null) {
  fileCacheManager!.markLocal(messageId: ack.messageId, localPath: localPath);
}
```

---

## 任务 3：local_store.dart — 加 localData 操作方法 `⬜ 待处理`

文件：`client/modules/flash_im_cache/lib/src/local_store.dart`

### 3.1 新增 updateLocalData 方法 `⬜`

在 `LocalStore` 抽象类中新增：

```dart
/// 更新消息的本地文件缓存路径
Future<void> updateLocalData(String messageId, String? localDataJson);
```

### 3.2 新增 getLocalData 方法 `⬜`

```dart
/// 读取消息的本地文件缓存路径
Future<String?> getLocalData(String messageId);
```

### 3.3 新增 batchGetLocalData 方法 `⬜`

```dart
/// 批量读取消息的 localData（用于列表预检）
Future<Map<String, String?>> batchGetLocalData(List<String> messageIds);
```

### 3.4 EmptyLocalStore 补齐实现 `⬜`

文件：`client/modules/flash_im_cache/lib/src/empty_local_store.dart`

三个方法都返回空值/空 Map 即可。

---

## 任务 4：CachedMessagesTable — 加 localData 列 + 迁移 `⬜ 待处理`

文件：`client/modules/flash_im_cache_drift/lib/src/database/tables/cached_messages_table.dart`

### 4.1 表定义加列 `⬜`

```dart
TextColumn get localData => text().nullable()();
```

### 4.2 数据库版本升级 `⬜`

文件：`client/modules/flash_im_cache_drift/lib/src/database/app_database.dart`

```dart
@override
int get schemaVersion => 3;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.createTable(localTrashTable);
    }
    if (from < 3) {
      await m.addColumn(cachedMessagesTable, cachedMessagesTable.localData);
    }
  },
);
```

---

## 任务 5：MessageDao — 加 localData 操作 `⬜ 待处理`

文件：`client/modules/flash_im_cache_drift/lib/src/dao/message_dao.dart`

### 5.1 updateLocalData 方法 `⬜`

```dart
/// 更新单条消息的 localData 字段
Future<void> updateLocalData(String messageId, String? localDataJson) async {
  // update cachedMessagesTable set localData = ? where id = ?
}
```

### 5.2 getLocalData 方法 `⬜`

```dart
/// 读取单条消息的 localData
Future<String?> getLocalData(String messageId) async {
  // select localData from cachedMessagesTable where id = ?
}
```

### 5.3 batchGetLocalData 方法 `⬜`

```dart
/// 批量读取 localData（in 查询）
Future<Map<String, String?>> batchGetLocalData(List<String> messageIds) async {
  // select id, localData from cachedMessagesTable where id in (...)
  // 返回 Map<messageId, localDataJson>
}
```

---

## 任务 6：converters.dart — 同步 localData 映射 `⬜ 待处理`

文件：`client/modules/flash_im_cache_drift/lib/src/converters.dart`

### 6.1 fromMessageRow 加 localData `⬜`

```dart
CachedMessage fromMessageRow(CachedMessagesTableData row) {
  return CachedMessage(
    // ... 现有字段 ...
    localData: row.localData,
  );
}
```

### 6.2 toMessageCompanion 加 localData `⬜`

```dart
CachedMessagesTableCompanion toMessageCompanion(CachedMessage m) {
  return CachedMessagesTableCompanion(
    // ... 现有字段 ...
    localData: Value(m.localData),
  );
}
```

---

## 任务 7：DriftLocalStore — 实现新接口方法 `⬜ 待处理`

文件：`client/modules/flash_im_cache_drift/lib/src/drift_local_store.dart`

### 7.1 实现 updateLocalData `⬜`

```dart
@override
Future<void> updateLocalData(String messageId, String? localDataJson) async {
  await _messageDao.updateLocalData(messageId, localDataJson);
}
```

### 7.2 实现 getLocalData `⬜`

```dart
@override
Future<String?> getLocalData(String messageId) {
  return _messageDao.getLocalData(messageId);
}
```

### 7.3 实现 batchGetLocalData `⬜`

```dart
@override
Future<Map<String, String?>> batchGetLocalData(List<String> messageIds) {
  return _messageDao.batchGetLocalData(messageIds);
}
```

---

## 任务 8：运行 build_runner 重新生成 `⬜ 待处理`

目录：`client/modules/flash_im_cache_drift/`

### 8.1 执行代码生成 `⬜`

```bash
dart run build_runner build --delete-conflicting-outputs
```

确认 `app_database.g.dart` 重新生成，包含 `localData` 列。

---

## 任务 9：FileCacheManager 抽象接口 `⬜ 待处理`

文件：`client/modules/flash_im_cache/lib/src/file_cache_manager.dart`（新建）

### 9.1 定义 FileCategory 枚举 `⬜`

```dart
enum FileCategory { image, video, audio, file }
```

### 9.2 定义 DownloadFunction 类型别名 `⬜`

```dart
/// 下载函数签名，由调用方注入（解耦 dio）
typedef DownloadFunction = Future<void> Function(
  String url,
  String savePath, {
  void Function(double progress)? onProgress,
});
```

### 9.3 定义 FileCacheManager 抽象类 `⬜`

```dart
abstract class FileCacheManager {
  /// 获取文件本地路径。
  /// 已缓存且文件存在 → 直接返回；否则排入下载队列。
  Future<String> getFile({
    required String url,
    required String messageId,
    required FileCategory category,
    String? fileName,
    void Function(double)? onProgress,
  });

  /// 直接写入 localData（发送场景：文件已在本地）
  Future<void> markLocal({
    required String messageId,
    required String localPath,
  });

  /// 手动清除某消息的本地缓存
  Future<void> clearCache(String messageId);

  /// 释放资源
  void dispose();
}
```

---

## 任务 10：FileCacheManagerImpl 队列实现 `⬜ 待处理`

文件：`client/modules/flash_im_cache/lib/src/file_cache_manager_impl.dart`（新建）

### 10.1 类定义与构造 `⬜`

```dart
class FileCacheManagerImpl implements FileCacheManager {
  final LocalStore _store;
  final DownloadFunction _download;
  final String _baseDir; // {appSupportDir}/UserData/{userId}
  final int maxConcurrent;

  // 下载中的 URL → Completer（URL 去重）
  final Map<String, Completer<String>> _downloading = {};
  // 等待队列
  final Queue<_DownloadTask> _queue = Queue();
  // 当前活跃下载数
  int _activeCount = 0;

  FileCacheManagerImpl({
    required LocalStore store,
    required DownloadFunction download,
    required String baseDir,
    this.maxConcurrent = 3,
  }) : _store = store, _download = download, _baseDir = baseDir;
}
```

### 10.2 getFile 实现逻辑 `⬜`

步骤：
1. 调用 `_store.getLocalData(messageId)` 检查 localData
2. 有值 → 解析 JSON 取 path → 检查文件是否存在
3. 文件存在 → 直接返回 path
4. 文件不存在 → 清除 localData，走下载
5. 检查 `_downloading[url]`，有 → 共享 Completer
6. 无 → 创建 Completer，检查并发数
7. `_activeCount < maxConcurrent` → 立即下载
8. 否则 → 入 _queue
9. 下载完成 → 构建 localData JSON → `_store.updateLocalData()`
10. 从 `_downloading` 移除 → 取 _queue 下一个

### 10.3 _buildSavePath 方法 `⬜`

```dart
String _buildSavePath(String messageId, FileCategory category, String url, String? fileName) {
  // 路径：{_baseDir}/{category.name}/{messageId}.{ext}
  // ext 从 fileName 或 url 路径中提取
}
```

### 10.4 markLocal 实现 `⬜`

```dart
@override
Future<void> markLocal({required String messageId, required String localPath}) async {
  final String json = '{"path":"$localPath","cached_at":${DateTime.now().millisecondsSinceEpoch}}';
  await _store.updateLocalData(messageId, json);
}
```

### 10.5 clearCache 实现 `⬜`

```dart
@override
Future<void> clearCache(String messageId) async {
  final String? data = await _store.getLocalData(messageId);
  // 解析 path → 删除文件 → updateLocalData(messageId, null)
}
```

### 10.6 dispose 实现 `⬜`

清空 _queue，不中断进行中的下载（让它们自然完成）。

### 10.7 NoOpFileCacheManager 空实现（Web 平台） `⬜`

文件：`client/modules/flash_im_cache/lib/src/noop_file_cache_manager.dart`（新建）

Web 平台无 dart:io，提供空实现：

```dart
/// Web 平台空实现，所有方法 no-op。
class NoOpFileCacheManager implements FileCacheManager {
  @override
  Future<String> getFile({
    required String url,
    required String messageId,
    required FileCategory category,
    String? fileName,
    void Function(double)? onProgress,
  }) async => url; // 直接返回原始 URL，走浏览器缓存

  @override
  Future<void> markLocal({required String messageId, required String localPath}) async {}

  @override
  Future<void> clearCache(String messageId) async {}

  @override
  void dispose() {}
}
```

上层在 Web 平台时注入 `NoOpFileCacheManager()`，原生平台注入 `FileCacheManagerImpl`。

---

## 任务 11：flash_im_cache 导出新文件 `⬜ 待处理`

文件：`client/modules/flash_im_cache/lib/flash_im_cache.dart`

### 11.1 添加导出 `⬜`

```dart
export 'src/file_cache_manager.dart';
export 'src/file_cache_manager_impl.dart';
export 'src/noop_file_cache_manager.dart';
```

---

## 任务 12：ChatFileMixin 改造 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_file_mixin.dart`

### 12.1 新增 fileCacheManager 抽象 getter `⬜`

```dart
FileCacheManager? get fileCacheManager;
```

### 12.2 downloadFile 改用 FileCacheManager `⬜`

改造现有 `downloadFile` 方法：
1. 如果 `fileCacheManager != null` → 调用 `fileCacheManager!.getFile()`
2. 保留 `_emitDownloadUpdate` 进度回调
3. 下载完成后不再需要手动写路径（FCM 内部已写 localData）
4. 如果 `fileCacheManager == null` → fallback 到旧逻辑（兼容性）

### 12.3 发送成功后写 localData `⬜`

在 `sendImageFromFile`、`sendVideoFromFile`、`sendFileFromPicker`、`sendAudioFromFile` 中记录 `_pendingLocalPaths[localId] = filePath`（参见任务 2.5）。

ack 处理时取出路径调用 `fileCacheManager?.markLocal()`。

### 12.4 _getDownloadDir 改为 appSupportDir `⬜`

```dart
Future<String> _getDownloadDir() async {
  final Directory dir = await getApplicationSupportDirectory();
  return dir.path;
}
```

不再使用 `getTemporaryDirectory()`。

---

## 任务 13：ChatCubit 注入 FileCacheManager + 图片自动缓存 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_cubit.dart`

### 13.1 构造函数加 fileCacheManager 参数 `⬜`

```dart
ChatCubit({
  // ... 现有参数 ...
  FileCacheManager? fileCacheManager,
}) : _fileCacheManager = fileCacheManager, ...
```

### 13.2 实现 mixin 的 getter `⬜`

```dart
final FileCacheManager? _fileCacheManager;

@override
FileCacheManager? get fileCacheManager => _fileCacheManager;
```

### 13.3 上层初始化（ChatPage 或 DI 处） `⬜`

确认 ChatCubit 创建时传入 `FileCacheManager` 实例。按平台选择：
- **原生平台**（Android/iOS/Windows/macOS/Linux）：注入 `FileCacheManagerImpl`
  - 需要：`LocalStore` 实例 + `DownloadFunction`（封装 dio.download）+ `baseDir`
- **Web 平台**：注入 `NoOpFileCacheManager()`

判断方式：`kIsWeb`（来自 `package:flutter/foundation.dart`）。

### 13.4 loadMessages 后触发图片自动缓存 `⬜`

在 `loadMessages()` 完成后，遍历消息列表，对图片类型且 `localData == null` 的消息批量调用 `fileCacheManager?.getFile()`。下载完成后更新 Message.localData 并 emit 新状态。

```dart
Future<void> _autoCacheImages(List<Message> messages) async {
  if (fileCacheManager == null) return;
  final List<Message> needCache = messages
      .where((m) => m.isImage && m.localData == null && m.status == MessageStatus.sent)
      .toList();
  for (final Message msg in needCache) {
    // 不 await，并行触发（FCM 内部控制并发）
    fileCacheManager!.getFile(
      url: _fullUrl(msg.content),
      messageId: msg.id,
      category: FileCategory.image,
    ).then((String path) {
      // 更新内存中 Message 的 localData，emit
      _updateMessageLocalData(msg.id, path);
    }).catchError((_) {});
  }
}
```

---

## 任务 14：ImageBubble 改造 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/bubble/image_bubble.dart`

### 14.1 新增 localPath 参数 `⬜`

```dart
class ImageBubble extends StatelessWidget {
  // ... 现有字段 ...
  final String? localPath; // 本地缓存路径（从 localData 解析）
}
```

### 14.2 渲染逻辑改造 `⬜`

优先级：
1. `localPath != null` && 文件存在 → `Image.file(File(localPath))`
2. isLocal（发送中，content 是本地路径）→ `Image.file(File(content))`
3. 否则 → `Image.network(fullUrl)`（现有逻辑）

### 14.3 MessageBubble 传递 localPath `⬜`

在 `message_bubble.dart` 的 `_buildBubble()` 中，为 `ImageBubble` 传入从 ChatState 中获取的 localPath。

---

## 任务 15：VideoBubble 改造 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/bubble/video_bubble.dart`

### 15.1 新增 localThumbnailPath 参数 `⬜`

```dart
final String? localThumbnailPath; // 缩略图本地路径
```

### 15.2 缩略图渲染优先本地 `⬜`

优先级：
1. `localThumbnailPath != null` → `Image.file`
2. isLocalThumb（发送中）→ 现有逻辑
3. 否则 → `Image.network`

---

## 任务 16：AudioBubble 改造 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/bubble/audio_bubble.dart`

### 16.1 新增 localPath 参数 `⬜`

```dart
final String? localPath; // 本地音频文件路径
```

### 16.2 播放逻辑优先本地 `⬜`

`_audioUrl` getter 改为：
1. `localPath != null` → 返回本地路径（setFilePath）
2. 否则 → 现有网络 URL 逻辑

`_togglePlay` 中根据是否本地路径选择 `setFilePath` 或 `setUrl`。

---

## 任务 17：FileBubble 改造 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/bubble/file_bubble.dart`

### 17.1 增强 FileDownloadInfo 使用 `⬜`

FileBubble 已通过 `downloadInfo?.localPath` 显示下载完成状态。改造点：
- 如果消息已有 localData（从 ChatState 获取），初始状态直接为 done + localPath
- 不再显示下载按钮（isIdle），而是显示"已下载"状态

### 17.2 MessageBubble 传递初始 downloadInfo `⬜`

如果 localData 有值且文件存在，构建 `FileDownloadInfo(status: done, progress: 1.0, localPath: path)` 传入 FileBubble。

---

## 任务 18：Debug 面板显示 localData 信息 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/bubble/message_bubble.dart`

### 18.1 _showDebugInfo 新增 localData 展示 `⬜`

在 `_showDebugInfo` 方法的 `info` StringBuffer 中追加：

```dart
info.writeln('--- localData ---');
info.writeln('raw: ${message.localData ?? "null"}');
if (message.localData != null) {
  // 解析 JSON 展示
  final Map<String, dynamic> parsed = jsonDecode(message.localData!);
  info.writeln('path: ${parsed['path']}');
  info.writeln('cached_at: ${DateTime.fromMillisecondsSinceEpoch(parsed['cached_at'] as int)}');
  // 检查文件是否存在
  final bool exists = File(parsed['path'] as String).existsSync();
  info.writeln('file_exists: ${exists ? "✅" : "❌"}');
}
```

### 18.2 import 补充 `⬜`

在 `message_bubble.dart` 中添加 `import 'dart:convert'` 和 `import 'dart:io'`（用于 JSON 解析和文件检查）。

---

## 任务 19：编译验证 + 测试路径 `⬜ 待处理`

### 19.1 build_runner 无报错 `⬜`

```bash
cd client/modules/flash_im_cache_drift
dart run build_runner build --delete-conflicting-outputs
```

### 19.2 flutter analyze 无 error `⬜`

```bash
cd client
flutter analyze
```

### 19.3 手动验证路径 `⬜`

1. 启动 App → 打开一个有图片消息的聊天 → 观察图片加载
2. 退出聊天页 → 重新进入 → 图片应从本地加载（无网络请求）
3. 双击消息气泡 → debug 面板应显示 localData 信息
4. 发送一张图片 → 发送成功后双击该消息 → localData 应有值
5. 点击文件消息下载 → 下载完成后退出重进 → 应显示"已下载"状态
6. 断网 → 已缓存的图片/语音仍可正常显示/播放


---

## 任务 19：桌面端右键菜单 — 另存为 + 打开文件夹 `✅ 已完成`

文件：`client/modules/flash_im_chat/lib/src/view/desktop_context_menu.dart`、`message_action_menu.dart`

### 19.1 MenuAction 枚举加 openFolder / saveAs `✅`

### 19.2 DesktopContextMenu 接收 localPath，文件存在时追加菜单项 `✅`

### 19.3 MessageBubble 传递 cachedPath 给 DesktopContextMenu `✅`

---

## 任务 20：桌面端文件/视频点击行为改造 `✅ 已完成`

文件：`client/modules/flash_im_chat/lib/src/view/chat_page.dart`

### 20.1 onFileTap 桌面端：已缓存 → 系统打开，未缓存 → 下载后打开 `✅`

### 20.2 onVideoTap：已缓存 → 系统播放器，未缓存 → 下载后打开/播放 `✅`

### 20.3 _openFileFolder 使用 Process.start + 路径标准化 `✅`

### 20.4 _saveFileAs 使用 FilePicker.saveFile + File.copy `✅`

---

## 任务 21：发送大小限制 + toast 提示 `✅ 已完成`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_file_mixin.dart`、`chat_page.dart`

### 21.1 FileSendLimits 配置类（可构造自定义值） `✅`

```dart
class FileSendLimits {
  final int maxImageSize;    // 默认 50MB
  final int maxVideoSize;    // 默认 50MB
  final int maxFileSize;     // 默认 50MB
  final int maxAudioDurationMs; // 默认 2 分钟
}
```

### 21.2 各发送方法中加校验，超限抛 FileSizeExceedException `✅`

### 21.3 chat_page.dart _safeSend 包裹调用，catch 后 SnackBar 提示 `✅`

---

## 任务 22：全局初始化 + 注入 `✅ 已完成`

文件：`client/lib/main.dart`、`client/lib/src/home/view/home_actions_mixin.dart`

### 22.1 main.dart initCache() 中创建 globalFileCacheManager `✅`

### 22.2 disposeCache() 清理 globalFileCacheManager `✅`

### 22.3 home_actions_mixin 两处 ChatCubit 传入 fileCacheManager + baseUrl `✅`

---

## 任务 23：编译验证 + 手动测试 `✅ 已完成`

### 23.1 flutter analyze 无新增 error `✅`

### 23.2 手动验证全部通过 `✅`

- 图片自动缓存 ✅
- 视频封面缓存 ✅
- 音频自动缓存 ✅
- 文件下载 + 内存刷新 ✅
- 发送后 markLocal ✅
- 右键菜单另存为/打开文件夹 ✅
- 桌面端文件点击直接打开 ✅
- 桌面端视频点击系统播放 ✅
- 发送超限 toast 提示 ✅
- Debug 面板显示 localData ✅
