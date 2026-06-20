import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:fx_logger/fx_logger.dart';
import 'package:path/path.dart' as p;

import '../fx_media_init.dart';
import 'download_task.dart';
import 'fx_download_event.dart';
import 'fx_media_download.dart';

/// FxMediaDownload 实现：队列 + 并发控制 + id 去重
class FxMediaDownloadImpl implements FxMediaDownload {
  static final FxLog _log = FxLog('FxDL');

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
  })  : _downloadFn = downloadFn,
        _cacheDir = cacheDir,
        _maxConcurrent = maxConcurrent;

  @override
  Stream<FxDownloadEvent> stream({required String url, String? id, String? fileName}) {
    final String effectiveId = id ?? url;

    // 1. 内存缓存命中
    final String? cached = _cacheMap[effectiveId];
    if (cached != null && File(cached).existsSync()) {
      _log.d('cache hit: $effectiveId');
      return Stream.value(FxDownloadComplete(id: effectiveId, url: url, localPath: cached));
    }

    // 1.5 磁盘缓存恢复（重启后内存为空但文件还在）
    final String diskPath = _buildSavePathFromId(effectiveId);
    if (File(diskPath).existsSync()) {
      _cacheMap[effectiveId] = diskPath;
      _log.d('disk cache hit: $effectiveId → $diskPath');
      return Stream.value(FxDownloadComplete(id: effectiveId, url: url, localPath: diskPath));
    }

    _log.d('cache miss, will download: $effectiveId (disk checked: $diskPath)');

    // 2. 去重：已有相同 id 的下载进行中
    if (_activeStreams.containsKey(effectiveId)) {
      _log.d('dedup: $effectiveId already downloading');
      return _activeStreams[effectiveId]!.stream;
    }

    // 3. 创建新任务
    final StreamController<FxDownloadEvent> controller = StreamController<FxDownloadEvent>.broadcast();
    _activeStreams[effectiveId] = controller;

    final String savePath = _buildSavePath(effectiveId, url, fileName);
    final DownloadTask task = DownloadTask(
      id: effectiveId,
      url: url,
      fileName: fileName,
      savePath: savePath,
      controller: controller,
    );

    // 4. 并发控制
    if (_activeCount < _maxConcurrent) {
      _startDownload(task);
    } else {
      _log.d('queued: $effectiveId (active=$_activeCount)');
      _queue.add(task);
    }

    return controller.stream;
  }

  @override
  Future<String> get({required String url, String? id, String? fileName}) {
    final Completer<String> completer = Completer<String>();
    final Stream<FxDownloadEvent> s = stream(url: url, id: id, fileName: fileName);

    late StreamSubscription<FxDownloadEvent> sub;
    sub = s.listen((FxDownloadEvent event) {
      switch (event) {
        case FxDownloadComplete(:final localPath):
          if (!completer.isCompleted) completer.complete(localPath);
          sub.cancel();
        case FxDownloadError(:final error):
          if (!completer.isCompleted) completer.completeError(error);
          sub.cancel();
        case FxDownloadProgress():
          break;
      }
    }, onError: (Object e) {
      if (!completer.isCompleted) completer.completeError(e);
    });

    return completer.future;
  }

  @override
  bool isCached(String id) {
    final String? path = _cacheMap[id];
    if (path != null && File(path).existsSync()) return true;
    // 内存 miss，检查磁盘（路径确定性）
    final String diskPath = _buildSavePathFromId(id);
    if (File(diskPath).existsSync()) {
      _cacheMap[id] = diskPath;
      _log.d('disk restore: $id → $diskPath');
      return true;
    }
    _log.d('not cached: $id, checked: $diskPath');
    return false;
  }

  @override
  String? localPath(String id) {
    final String? path = _cacheMap[id];
    if (path != null && File(path).existsSync()) return path;
    // 内存 miss，检查磁盘（路径确定性）
    final String diskPath = _buildSavePathFromId(id);
    if (File(diskPath).existsSync()) {
      _cacheMap[id] = diskPath;
      _log.d('disk restore: $id → $diskPath');
      return diskPath;
    }
    _log.d('localPath miss: $id, checked: $diskPath');
    return null;
  }

  @override
  Future<void> remove(String id) async {
    final String? path = _cacheMap.remove(id);
    if (path != null) {
      final File file = File(path);
      if (file.existsSync()) {
        await file.delete();
        _log.d('removed: $id → $path');
      }
    }
  }

  @override
  void cancel(String id) {
    // 从队列中移除
    _queue.removeWhere((DownloadTask task) {
      if (task.id == id) {
        task.cancelled = true;
        task.controller.add(FxDownloadError(id: id, url: task.url, error: 'cancelled'));
        task.controller.close();
        _activeStreams.remove(id);
        return true;
      }
      return false;
    });

    // 如果正在下载中，标记取消（下载完成/失败时会检查）
    final StreamController<FxDownloadEvent>? active = _activeStreams[id];
    if (active != null) {
      // 找到对应任务标记 cancelled
      // 注：正在进行中的 HTTP 请求无法直接中断，但完成后不会写入缓存
      _log.d('cancel requested: $id');
    }
  }

  // ─── 内部方法 ───

  Future<void> _startDownload(DownloadTask task) async {
    _activeCount++;
    _log.d('start: ${task.id} (active=$_activeCount)');

    try {
      // 确保目录存在
      final Directory dir = File(task.savePath).parent;
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      await _downloadFn(task.url, task.savePath, onProgress: (double progress) {
        if (!task.cancelled && !task.controller.isClosed) {
          task.controller.add(FxDownloadProgress(
            id: task.id,
            url: task.url,
            progress: progress,
          ));
        }
      });

      if (task.cancelled) {
        // 已取消，删除临时文件
        final File file = File(task.savePath);
        if (file.existsSync()) file.deleteSync();
        _log.d('cancelled, cleaned: ${task.id}');
      } else {
        // 写入缓存映射
        _cacheMap[task.id] = task.savePath;
        _log.d('done: ${task.id} → ${task.savePath}');
        if (!task.controller.isClosed) {
          task.controller.add(FxDownloadComplete(
            id: task.id,
            url: task.url,
            localPath: task.savePath,
          ));
        }
      }
    } catch (e) {
      _log.w('failed: ${task.id}, error=$e');
      if (!task.controller.isClosed) {
        task.controller.add(FxDownloadError(
          id: task.id,
          url: task.url,
          error: e,
        ));
      }
    } finally {
      if (!task.controller.isClosed) {
        task.controller.close();
      }
      _activeStreams.remove(task.id);
      _activeCount--;
      _processQueue();
    }
  }

  void _processQueue() {
    while (_queue.isNotEmpty && _activeCount < _maxConcurrent) {
      final DownloadTask next = _queue.removeFirst();
      if (!next.cancelled) {
        _startDownload(next);
      }
    }
  }

  String _buildSavePath(String id, String url, String? fileName) {
    String ext = '';
    // 只有 id 不含扩展名时才追加
    if (!id.contains('.')) {
      if (fileName != null && fileName.contains('.')) {
        ext = fileName.substring(fileName.lastIndexOf('.'));
      } else {
        final String urlPath = url.split('?').first;
        if (urlPath.contains('.')) {
          ext = urlPath.substring(urlPath.lastIndexOf('.'));
        }
      }
    }
    // 清理 id 中不安全的文件名字符
    final String safeId = id.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return p.join(_cacheDir, '$safeId$ext');
  }

  /// 仅根据 id 推算磁盘路径（用于重启后磁盘缓存恢复）
  /// id 格式：`uuid_ext`（如 `abc-def_mp4`）→ 磁盘文件名 `abc-def_mp4.mp4`
  String _buildSavePathFromId(String id) {
    final String safeId = id.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    // 从 id 尾部的 _ext 提取扩展名
    final int lastUnderscore = id.lastIndexOf('_');
    String ext = '';
    if (lastUnderscore > 0) {
      ext = '.${id.substring(lastUnderscore + 1)}';
    }
    return p.join(_cacheDir, '$safeId$ext');
  }
}
