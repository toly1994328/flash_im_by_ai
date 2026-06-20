# fx_media — 客户端任务清单

基于 client/design.md 设计，列出需要创建/修改的具体细节。

全局约束：
- fx_media 包不依赖任何闪讯业务模型（Message、Conversation 等）
- fx_media 包不直接依赖 dio，通过 typedef 注入下载函数
- 日志使用 fx_logger：`final _log = FxLog('Tag')`
- 变量必须显式标注类型
- 迁移后 CloudDownloadManager 和 VideoPlayerPage（flash_im_chat）删除

---

## 执行顺序

1. ⬜ 任务 1 — fx_media 包骨架（pubspec + barrel export + FxMedia 入口）
2. ⬜ 任务 2 — 下载事件模型（FxDownloadEvent sealed class）
3. ⬜ 任务 3 — 下载管理实现（FxMediaDownload + 队列 + 并发 + 去重）
4. ⬜ 任务 4 — 音频状态模型 + 全局音频播放器实现
5. ⬜ 任务 5 — 图片模块（FxMediaImage + FxCachedImage Widget）
6. ⬜ 任务 6 — 视频模块（FxMediaVideo + 全屏播放页）
7. ⬜ 任务 7 — 文件模块（FxMediaFile：打开/另存为/打开文件夹）
8. ⬜ 任务 8 — 主应用集成（pubspec 依赖 + main.dart 初始化）
9. ⬜ 任务 9 — 迁移 ChatMediaHandler
10. ⬜ 任务 10 — 迁移 AudioBubble
11. ⬜ 任务 11 — 迁移 ImageBubble
12. ⬜ 任务 12 — 迁移 ChatCubit / chat_file_mixin
13. ⬜ 任务 13 — 迁移 flash_cloud（FileDetailCubit）
14. ⬜ 任务 14 — 删除废弃文件 + 清理导出
15. ⬜ 任务 15 — 编译验证

---

## 任务 1：包骨架 `⬜ 待处理`

文件：`client/packages/fx_media/pubspec.yaml`（新建）
文件：`client/packages/fx_media/lib/fx_media.dart`（新建）
文件：`client/packages/fx_media/lib/src/fx_media_init.dart`（新建）

### 1.1 pubspec.yaml `⬜`

```yaml
name: fx_media
description: 通用媒体管理包（下载/缓存/播放/预览/打开）
version: 0.0.1

environment:
  sdk: ^3.6.0
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  fx_logger:
    path: ../fx_logger
  just_audio: ^0.9.43
  video_player: ^2.9.3
  flutter_cache_manager: ^3.4.1
  cached_network_image: ^3.4.1
  tolyui_mediax_core: ^0.1.0
  tolyui_mediax_ui: ^0.1.0
  file_picker: ^8.3.7
  open_file: ^3.5.10
  path: ^1.9.1
```

注：tolyui_mediax_core 和 tolyui_mediax_ui 使用项目已有的 dependency_overrides 指向本地路径。

### 1.2 barrel export（fx_media.dart） `⬜`

导出所有公开 API：

```dart
library;

export 'src/fx_media_init.dart';
export 'src/download/fx_download_event.dart';
export 'src/download/fx_media_download.dart';
export 'src/audio/fx_audio_state.dart';
export 'src/audio/fx_media_audio.dart';
export 'src/image/fx_media_image.dart';
export 'src/image/fx_cached_image.dart';
export 'src/video/fx_media_video.dart';
export 'src/file/fx_media_file.dart';
```

### 1.3 FxMedia 入口类（fx_media_init.dart） `⬜`

```dart
typedef FxDownloadFunction = Future<void> Function(
  String url,
  String savePath, {
  void Function(double progress)? onProgress,
});

class FxMedia {
  static late final FxMediaDownload download;
  static late final FxMediaAudio audio;
  static late final FxMediaImage image;
  static late final FxMediaVideo video;
  static late final FxMediaFile file;

  static bool _initialized = false;

  static void init({
    required String cacheDir,
    required FxDownloadFunction downloadFn,
    int maxConcurrent = 5,
  });
  // 逻辑：
  // 1. 断言 !_initialized 防止重复初始化
  // 2. 创建各子模块实例，赋值给 static late final
  // 3. _initialized = true
}
```

---

## 任务 2：下载事件模型 `⬜ 待处理`

文件：`client/packages/fx_media/lib/src/download/fx_download_event.dart`（新建）

### 2.1 sealed class 定义 `⬜`

```dart
sealed class FxDownloadEvent {
  final String id;
  final String url;
  const FxDownloadEvent({required this.id, required this.url});
}

class FxDownloadProgress extends FxDownloadEvent {
  final double progress;
  const FxDownloadProgress({required super.id, required super.url, required this.progress});
}

class FxDownloadComplete extends FxDownloadEvent {
  final String localPath;
  const FxDownloadComplete({required super.id, required super.url, required this.localPath});
}

class FxDownloadError extends FxDownloadEvent {
  final Object error;
  const FxDownloadError({required super.id, required super.url, required this.error});
}
```

---

## 任务 3：下载管理实现 `⬜ 待处理`

文件：`client/packages/fx_media/lib/src/download/fx_media_download.dart`（新建）
文件：`client/packages/fx_media/lib/src/download/fx_media_download_impl.dart`（新建）
文件：`client/packages/fx_media/lib/src/download/download_task.dart`（新建）

### 3.1 抽象接口（fx_media_download.dart） `⬜`

```dart
abstract class FxMediaDownload {
  Stream<FxDownloadEvent> stream({required String url, String? id, String? fileName});
  Future<String> get({required String url, String? id, String? fileName});
  bool isCached(String id);
  String? localPath(String id);
  Future<void> remove(String id);
  void cancel(String id);
}
```

### 3.2 内部任务模型（download_task.dart） `⬜`

不导出，仅内部使用：

```dart
class DownloadTask {
  final String id;
  final String url;
  final String? fileName;
  final StreamController<FxDownloadEvent> controller;
  bool cancelled = false;

  DownloadTask({required this.id, required this.url, this.fileName, required this.controller});
}
```

### 3.3 实现类（fx_media_download_impl.dart） `⬜`

```dart
class FxMediaDownloadImpl implements FxMediaDownload {
  final FxDownloadFunction _downloadFn;
  final String _cacheDir;
  final int _maxConcurrent;

  /// id → localPath 缓存映射（内存）
  final Map<String, String> _cacheMap = {};
  /// id → 正在进行的下载 StreamController（去重）
  final Map<String, StreamController<FxDownloadEvent>> _activeStreams = {};
  /// 等待队列
  final Queue<DownloadTask> _queue = Queue();
  /// 当前活跃下载数
  int _activeCount = 0;

  FxMediaDownloadImpl({
    required FxDownloadFunction downloadFn,
    required String cacheDir,
    required int maxConcurrent,
  });
}
```

核心逻辑步骤（stream 方法）：
1. id 为空时取 url 作为 id
2. 检查 `_cacheMap[id]` → 命中且文件存在 → 直接发 Complete 关闭
3. 检查 `_activeStreams[id]` → 有则返回已有 stream
4. 创建 DownloadTask，计算 savePath = `_cacheDir/{category}/{id}{ext}`
5. 并发检查：`_activeCount < _maxConcurrent` → 启动；否则入队列
6. 下载完成后：更新 `_cacheMap`，从 `_activeStreams` 移除，发 Complete，检查队列

savePath 推导：
- 从 fileName 或 url 提取扩展名
- 路径格式：`{_cacheDir}/{id}{ext}`（用 id 做文件名，保证唯一）

cancel 方法：
- 标记 task.cancelled = true
- 如果在队列中 → 移除
- 如果正在下载 → 发 Error 事件，关闭 stream（下载函数内部靠 cancelled 标志提前终止）

---

## 任务 4：音频模块 `⬜ 待处理`

文件：`client/packages/fx_media/lib/src/audio/fx_audio_state.dart`（新建）
文件：`client/packages/fx_media/lib/src/audio/fx_media_audio.dart`（新建）
文件：`client/packages/fx_media/lib/src/audio/fx_media_audio_impl.dart`（新建）

### 4.1 状态模型（fx_audio_state.dart） `⬜`

```dart
enum FxAudioState { idle, loading, playing, paused, completed, error }

class FxAudioSnapshot {
  final FxAudioState state;
  final String? currentId;
  final Duration position;
  final Duration duration;

  const FxAudioSnapshot({
    this.state = FxAudioState.idle,
    this.currentId,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });
}
```

### 4.2 抽象接口（fx_media_audio.dart） `⬜`

```dart
abstract class FxMediaAudio {
  Future<void> play(String url, {String? id});
  Future<void> playFile(String localPath, {String? id});
  Future<void> pause();
  Future<void> stop();
  String? get currentId;
  Stream<FxAudioSnapshot> get snapshotStream;
  void dispose();
}
```

### 4.3 实现类（fx_media_audio_impl.dart） `⬜`

```dart
class FxMediaAudioImpl implements FxMediaAudio {
  final AudioPlayer _player = AudioPlayer();
  String? _currentId;
  final StreamController<FxAudioSnapshot> _snapshotController = StreamController.broadcast();
}
```

核心逻辑：
1. `play(url, {id})` → 如果 `_currentId != id`，先 stop 再 setUrl + play
2. `playFile(path, {id})` → 同上，用 setFilePath
3. 监听 `_player.playerStateStream` + `_player.positionStream` → 组合发射 FxAudioSnapshot
4. 播完自动发 `completed`，不 dispose player（复用实例）
5. `dispose()` → 关 player + 关 controller

---

## 任务 5：图片模块 `⬜ 待处理`

文件：`client/packages/fx_media/lib/src/image/fx_media_image.dart`（新建）
文件：`client/packages/fx_media/lib/src/image/fx_media_image_impl.dart`（新建）
文件：`client/packages/fx_media/lib/src/image/fx_cached_image.dart`（新建）

### 5.1 抽象接口（fx_media_image.dart） `⬜`

```dart
abstract class FxMediaImage {
  void preview(
    BuildContext context, {
    required List<ImageMeta> items,
    int initialIndex = 0,
    VoidCallback? onDismiss,
  });

  Widget cached({
    required String url,
    String? id,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Map<String, String>? headers,
    void Function(String localPath)? onCached,
  });
}
```

### 5.2 实现类（fx_media_image_impl.dart） `⬜`

- `preview`：复制当前 ChatMediaHandler.openImage 的 Navigator.push 逻辑，使用 MediaPreviewPage + ImageViewer
- `cached`：返回 FxCachedImage Widget

### 5.3 FxCachedImage Widget（fx_cached_image.dart） `⬜`

```dart
class FxCachedImage extends StatefulWidget {
  final String url;
  final String? id;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Map<String, String>? headers;
  final void Function(String localPath)? onCached;
  // ...
}
```

核心逻辑（State）：
1. build 用 CachedNetworkImage 渲染，cacheManager 用 PersistentCacheManager 风格（stalePeriod 365 天）
2. 图片加载完成后（imageBuilder 或 didUpdateWidget），调用 `cacheManager.getFileFromCache(url)` 获取路径
3. 获取到路径后调用 `onCached?.call(localPath)`
4. 用 `_hasCalled` 标志位防止重复回调

---

## 任务 6：视频模块 `⬜ 待处理`

文件：`client/packages/fx_media/lib/src/video/fx_media_video.dart`（新建）
文件：`client/packages/fx_media/lib/src/video/fx_media_video_impl.dart`（新建）
文件：`client/packages/fx_media/lib/src/video/fx_video_player_page.dart`（新建）

### 6.1 抽象接口（fx_media_video.dart） `⬜`

```dart
abstract class FxMediaVideo {
  void open(BuildContext context, String url);
  void openFile(BuildContext context, String localPath);
}
```

### 6.2 实现类（fx_media_video_impl.dart） `⬜`

- `open` → Navigator.push → FxVideoPlayerPage(source: NetworkSource)
- `openFile` → Navigator.push → FxVideoPlayerPage(source: FileSource)

### 6.3 全屏播放页（fx_video_player_page.dart） `⬜`

基于现有 VideoPlayerPage 改造：

```dart
class FxVideoPlayerPage extends StatefulWidget {
  final String source;    // URL 或本地路径
  final bool isLocal;
}
```

改动点：
- initState 中根据 `isLocal` 选择 `VideoPlayerController.file(File(source))` 或 `VideoPlayerController.networkUrl(Uri.parse(source))`
- 控制条保持现有样式不变
- 其余逻辑与旧 VideoPlayerPage 一致

---

## 任务 7：文件模块 `⬜ 待处理`

文件：`client/packages/fx_media/lib/src/file/fx_media_file.dart`（新建）
文件：`client/packages/fx_media/lib/src/file/fx_media_file_impl.dart`（新建）

### 7.1 抽象接口（fx_media_file.dart） `⬜`

```dart
abstract class FxMediaFile {
  Future<void> open(String localPath);
  Future<void> saveAs(String localPath, {String? suggestedName});
  Future<void> openFolder(String localPath);
}
```

### 7.2 实现类（fx_media_file_impl.dart） `⬜`

核心逻辑：

- `open`：
  - 桌面端：`Process.start('cmd', ['/c', 'start', '', localPath])`（Windows），`Process.run('open', [localPath])`（macOS）
  - 移动端：使用 `open_file` 包的 `OpenFile.open(localPath)`

- `saveAs`：
  - 调用 `FilePicker.platform.saveFile(dialogTitle: '另存为', fileName: suggestedName ?? basename)`
  - 用户选了路径后 `File(localPath).copy(outputPath)`

- `openFolder`：
  - Windows：`Process.start('explorer.exe', ['/select,$normalizedPath'])`
  - macOS：`Process.run('open', ['-R', localPath])`
  - Linux：`Process.run('xdg-open', [parentDir])`
  - 移动端：no-op（移动端无此概念）

---

## 任务 8：主应用集成 `⬜ 待处理`

文件：`client/pubspec.yaml`（修改）
文件：`client/lib/main.dart`（修改）

### 8.1 pubspec.yaml 添加依赖 `⬜`

```yaml
dependencies:
  fx_media:
    path: packages/fx_media
```

### 8.2 main.dart 初始化 `⬜`

在现有 `CloudDownloadManager().init(...)` 位置替换为：

```dart
import 'package:fx_media/fx_media.dart';

// 获取 cacheDir
final Directory cacheDir = await getApplicationCacheDirectory();
final String mediaCacheDir = '${cacheDir.path}/fx_media';

FxMedia.init(
  cacheDir: mediaCacheDir,
  downloadFn: (String url, String savePath, {void Function(double)? onProgress}) async {
    await httpClient.dio.download(url, savePath, onReceiveProgress: (int count, int total) {
      if (total > 0 && onProgress != null) {
        onProgress(count / total);
      }
    });
  },
  maxConcurrent: 5,
);
```

删除 `CloudDownloadManager().init(...)` 那一行。

---

## 任务 9：迁移 ChatMediaHandler `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/logic/handler/chat_media_handler.dart`（修改）

### 9.1 替换图片预览 `⬜`

- 删除 openImage 内部的 Navigator.push + MediaPreviewPage 构建逻辑
- 改为：

```dart
void openImage(BuildContext context, Message msg, {List<Message>? imageMessages, int? index}) {
  final List<ImageMeta> items = (imageMessages ?? [msg])
      .map((m) => m.toImageMeta(baseUrl: baseUrl ?? ''))
      .toList();
  FxMedia.image.preview(context, items: items, initialIndex: index ?? 0);
}
```

### 9.2 替换视频打开 `⬜`

- 删除旧的条件判断逻辑（桌面端 Process.start / 移动端 VideoPlayerPage）
- 改为：

```dart
Future<void> openVideo(BuildContext context, Message msg) async {
  final String? cachedPath = extractLocalPath(msg);
  if (cachedPath != null && File(cachedPath).existsSync()) {
    // 已缓存
    if (kApp.isDesktop) {
      await FxMedia.file.open(cachedPath);
    } else {
      FxMedia.video.openFile(context, cachedPath);
    }
  } else {
    // 未缓存：下载后打开
    final String videoUrl = _fullUrl(msg.content);
    final String localPath = await FxMedia.download.get(url: videoUrl, id: msg.id);
    _cubit.updateMessageLocalData(msg.id, localPath);
    if (!context.mounted) return;
    if (kApp.isDesktop) {
      await FxMedia.file.open(localPath);
    } else {
      FxMedia.video.openFile(context, localPath);
    }
  }
}
```

### 9.3 替换文件操作 `⬜`

- `openFile`：桌面端下载部分改用 `FxMedia.download.get` + `FxMedia.file.open`
- `openFileFolder`：改为 `FxMedia.file.openFolder(localPath)`
- `saveFileAs`：改为 `FxMedia.file.saveAs(localPath, suggestedName: fileName)`

### 9.4 清理 import `⬜`

- 删除 `import 'package:flash_im_cache/flash_im_cache.dart' show FileCacheManager, FileCategory`
- 删除 `import '../../view/media/video_player_page.dart'`
- 添加 `import 'package:fx_media/fx_media.dart'`

---

## 任务 10：迁移 AudioBubble `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/bubble/audio_bubble.dart`（修改）

### 10.1 去掉内部 AudioPlayer `⬜`

- 删除 `final AudioPlayer _player = AudioPlayer()` 和 initState 中的 playerStateStream 监听
- 删除 dispose 中的 `_player.dispose()`
- 删除 `_togglePlay` 中的 player 操作

### 10.2 改用 FxMedia.audio `⬜`

```dart
class _AudioBubbleState extends State<AudioBubble> {
  StreamSubscription<FxAudioSnapshot>? _sub;

  String get _audioId => widget.message.id;

  bool get _isPlaying {
    return FxMedia.audio.currentId == _audioId;
    // 精确状态由 snapshotStream 驱动 rebuild
  }

  @override
  void initState() {
    super.initState();
    _sub = FxMedia.audio.snapshotStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (FxMedia.audio.currentId == _audioId) {
      // 当前正在播放这条 → 暂停/恢复
      await FxMedia.audio.pause();
    } else {
      final String url = _audioUrl;
      if (_isLocalFile) {
        await FxMedia.audio.playFile(url, id: _audioId);
      } else {
        await FxMedia.audio.play(url, id: _audioId);
      }
    }
  }
}
```

### 10.3 更新 import `⬜`

- 删除 `import 'package:just_audio/just_audio.dart'`
- 添加 `import 'package:fx_media/fx_media.dart'`

---

## 任务 11：迁移 ImageBubble `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/bubble/image_bubble.dart`（修改）

### 11.1 已发送图片改用 FxMedia.image.cached `⬜`

当前已发送状态用 `MediaImageView`，改为：

```dart
// 已发送：用 FxMedia.image.cached（自动缓存 + 回调路径）
Widget _buildNetworkImage(ImageMeta meta, double width, double height, bool crop) {
  final String url = switch (meta.source) {
    NetworkSource(:final uri) => uri.toString(),
    _ => '',
  };
  if (url.isEmpty) return _buildFromMeta(meta, width, height, crop);

  return GestureDetector(
    onTap: onTap,
    child: Hero(
      tag: meta.heroTag ?? meta.hashCode,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x1A000000), width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FxMedia.image.cached(
            url: url,
            id: message.id,
            fit: BoxFit.cover,
            width: width,
            height: height,
            onCached: (String localPath) {
              // 通知业务层更新 localData
              // 通过回调传出去，由 ChatPage 层处理
            },
          ),
        ),
      ),
    ),
  );
}
```

注意：如果 meta.source 是 FileSource（本地已有），保持现有 Image.file 逻辑不变。只有 NetworkSource 才走 FxMedia.image.cached。

### 11.2 添加 onCached 回调参数 `⬜`

ImageBubble 新增可选参数：

```dart
final void Function(String messageId, String localPath)? onCached;
```

在 FxMedia.image.cached 的 onCached 中调用：`widget.onCached?.call(widget.message.id, localPath)`

### 11.3 更新 import `⬜`

- 添加 `import 'package:fx_media/fx_media.dart'`

---

## 任务 12：迁移 ChatCubit / chat_file_mixin `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_cubit.dart`（修改）
文件：`client/modules/flash_im_chat/lib/src/logic/chat_file_mixin.dart`（修改）

### 12.1 chat_file_mixin：downloadFile 改用 FxMedia.download `⬜`

```dart
Future<void> downloadFile(String messageId, String fullUrl, String fileName) async {
  // ...状态检查不变...
  _emitDownloadUpdate(messageId, const FileDownloadInfo(status: FileDownloadStatus.downloading));

  try {
    final String localPath = await FxMedia.download.get(url: fullUrl, id: messageId, fileName: fileName);
    _emitDownloadUpdate(messageId, FileDownloadInfo(
      status: FileDownloadStatus.done, progress: 1.0, localPath: localPath,
    ));
    _updateLocalDataInState(messageId, localPath);
  } catch (e) {
    _emitDownloadUpdate(messageId, FileDownloadInfo(
      status: FileDownloadStatus.error, error: e.toString(),
    ));
  }
}
```

注意：当前 downloadFile 没有进度回调了（FxMedia.download.get 只返回最终结果）。如果需要进度，改用 stream 方式：

```dart
FxMedia.download.stream(url: fullUrl, id: messageId, fileName: fileName).listen((event) {
  switch (event) {
    case FxDownloadProgress(:final progress):
      _emitDownloadUpdate(messageId, FileDownloadInfo(status: FileDownloadStatus.downloading, progress: progress));
    case FxDownloadComplete(:final localPath):
      _emitDownloadUpdate(messageId, FileDownloadInfo(status: FileDownloadStatus.done, progress: 1.0, localPath: localPath));
      _updateLocalDataInState(messageId, localPath);
    case FxDownloadError(:final error):
      _emitDownloadUpdate(messageId, FileDownloadInfo(status: FileDownloadStatus.error, error: error.toString()));
  }
});
```

推荐使用 stream 方式保留进度。

### 12.2 chat_cubit：_autoCacheImages 改用 FxMedia.download `⬜`

当前 `_autoCacheImages` 调用 `_fileCacheManager.getFile()` 预缓存图片/视频封面/音频。改为：

```dart
void _autoCacheImages(List<Message> messages) {
  for (final Message msg in messages) {
    if (msg.localData != null) continue; // 已有本地数据跳过
    final String url = _buildFullUrl(msg.content);

    switch (msg.type) {
      case MessageType.image:
        FxMedia.download.get(url: url, id: msg.id).then((String path) {
          updateMessageLocalData(msg.id, path);
        }).catchError((_) {});
      case MessageType.video:
        final String? thumbUrl = msg.extra?['thumbnail_url'] as String?;
        if (thumbUrl != null) {
          FxMedia.download.get(url: _buildFullUrl(thumbUrl), id: '${msg.id}_thumb').catchError((_) {});
        }
      case MessageType.audio:
        FxMedia.download.get(url: url, id: msg.id).then((String path) {
          updateMessageLocalData(msg.id, path);
        }).catchError((_) {});
      default:
        break;
    }
  }
}
```

### 12.3 chat_cubit：移除 fileCacheManager 参数 `⬜`

- 删除构造参数 `FileCacheManager? fileCacheManager`
- 删除字段 `final FileCacheManager? _fileCacheManager`
- 删除 getter `FileCacheManager? get fileCacheManager`
- chat_file_mixin 中删除 `fileCacheManager` 抽象 getter
- 所有创建 ChatCubit 的地方删除 `fileCacheManager: xxx` 参数

### 12.4 更新 import `⬜`

- 删除 `import 'package:flash_im_cache/flash_im_cache.dart' show FileCacheManager, FileCategory`
- 添加 `import 'package:fx_media/fx_media.dart'`

---

## 任务 13：迁移 flash_cloud `⬜ 待处理`

文件：`client/modules/flash_cloud/lib/src/logic/file_detail_cubit.dart`（修改）
文件：`client/modules/flash_cloud/lib/flash_cloud.dart`（修改）
文件：`client/modules/flash_cloud/pubspec.yaml`（修改）

### 13.1 FileDetailState 改用 FxDownloadEvent 风格 `⬜`

当前 State 中有 `DownloadInfo downloadInfo`。改为更简单的字段：

```dart
class FileDetailState {
  final FileDetailStatus status;
  final CloudFileDetail? detail;
  final double downloadProgress;    // 0.0 ~ 1.0
  final String? localPath;          // 下载完成后的路径
  final bool isDownloading;
  final String? error;

  bool get isCached => localPath != null;
  // ...
}
```

### 13.2 FileDetailCubit 改用 FxMedia.download `⬜`

```dart
class FileDetailCubit extends Cubit<FileDetailState> {
  StreamSubscription<FxDownloadEvent>? _downloadSub;

  /// 下载文件
  void downloadToLocal() {
    if (state.detail == null) return;
    final String url = state.detail!.file.url;
    final String id = state.detail!.file.id.toString();

    emit(state.copyWith(isDownloading: true, downloadProgress: 0.0));

    _downloadSub = FxMedia.download.stream(url: url, id: id).listen((FxDownloadEvent event) {
      switch (event) {
        case FxDownloadProgress(:final progress):
          emit(state.copyWith(downloadProgress: progress));
        case FxDownloadComplete(:final localPath):
          emit(state.copyWith(isDownloading: false, downloadProgress: 1.0, localPath: localPath));
        case FxDownloadError(:final error):
          emit(state.copyWith(isDownloading: false, error: error.toString()));
      }
    });
  }

  /// 加载详情时检查缓存
  Future<void> loadDetail(int fileId) async {
    // ...加载详情...
    final String id = fileId.toString();
    final String? cached = FxMedia.download.localPath(id);
    emit(FileDetailState(
      status: FileDetailStatus.loaded,
      detail: detail,
      localPath: cached,
    ));
  }

  /// 清除缓存
  Future<void> clearLocalCache() async {
    if (state.detail == null) return;
    final String id = state.detail!.file.id.toString();
    await FxMedia.download.remove(id);
    emit(state.copyWith(localPath: null));
  }
}
```

### 13.3 flash_cloud barrel 移除 CloudDownloadManager 导出 `⬜`

```dart
// 删除这行：
// export 'src/data/cloud_download_manager.dart';
```

### 13.4 pubspec.yaml 添加 fx_media 依赖 `⬜`

```yaml
dependencies:
  fx_media:
    path: ../../packages/fx_media
```

---

## 任务 14：删除废弃文件 + 清理 `⬜ 待处理`

### 14.1 删除 CloudDownloadManager `⬜`

删除文件：`client/modules/flash_cloud/lib/src/data/cloud_download_manager.dart`

### 14.2 删除旧 VideoPlayerPage `⬜`

删除文件：`client/modules/flash_im_chat/lib/src/view/media/video_player_page.dart`

### 14.3 清理 main.dart `⬜`

- 删除 `import 'package:flash_cloud/flash_cloud.dart'` 中对 CloudDownloadManager 的引用（如果 import 只为它）
- 删除 `CloudDownloadManager().init(...)` 行

### 14.4 清理 flash_im_cache `⬜`

FileCacheManager 接口和 FileCacheManagerImpl 暂时保留（可能其他地方还在用），但 chat_cubit 不再传入。后续版本可考虑删除。

---

## 任务 15：编译验证 `⬜ 待处理`

### 15.1 flutter analyze `⬜`

```bash
cd client && flutter analyze
```

要求：零错误、零警告。

### 15.2 flutter build `⬜`

```bash
cd client && flutter build apk --debug
```

或 Windows 桌面：

```bash
cd client && flutter build windows
```

要求：构建成功。

### 15.3 手动验证路径 `⬜`

- 聊天发图 → 点击预览 → 滑动 + 缩放 + 退出
- 聊天发视频 → 点击播放 → 全屏播放正常
- 聊天发语音 → 播新停旧 → 暂停恢复
- 聊天发文件 → 下载 → 打开 / 另存为 / 打开文件夹
- 云空间文件 → 下载 → 进度显示 → 完成后打开
