import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:fx_logger/fx_logger.dart';
import 'package:path/path.dart' as p;

import 'file_cache_manager.dart';
import 'local_store.dart';

/// 下载任务内部模型
class _DownloadTask {
  final String url;
  final String messageId;
  final FileCategory category;
  final String? fileName;
  final void Function(double)? onProgress;
  final Completer<String> completer;

  _DownloadTask({
    required this.url,
    required this.messageId,
    required this.category,
    this.fileName,
    this.onProgress,
    required this.completer,
  });
}

/// FileCacheManager 原生平台实现
///
/// 下载队列 + 并发控制 + URL 去重 + 本地路径持久化。
/// 依赖 dart:io（File 类），Web 平台请使用 NoOpFileCacheManager。
class FileCacheManagerImpl implements FileCacheManager {
  static final _log = FxLog('FileCache');

  final LocalStore _store;
  final DownloadFunction _download;
  final String _baseDir;
  final int maxConcurrent;

  /// 下载中的 URL → Completer（URL 去重）
  final Map<String, Completer<String>> _downloading = {};

  /// 等待队列
  final Queue<_DownloadTask> _queue = Queue();

  /// 当前活跃下载数
  int _activeCount = 0;

  FileCacheManagerImpl({
    required LocalStore store,
    required DownloadFunction download,
    required String baseDir,
    this.maxConcurrent = 3,
  })  : _store = store,
        _download = download,
        _baseDir = baseDir;

  @override
  Future<String> getFile({
    required String url,
    required String messageId,
    required FileCategory category,
    String? fileName,
    void Function(double)? onProgress,
  }) async {
    // 1. 检查本地缓存
    final String? localDataJson = await _store.getLocalData(messageId);
    if (localDataJson != null) {
      try {
        final Map<String, dynamic> parsed =
            jsonDecode(localDataJson) as Map<String, dynamic>;
        final String path = parsed['path'] as String;
        if (File(path).existsSync()) {
          _log.d('cache hit: $messageId → $path');
          return path;
        }
        // 文件不存在，清除 localData
        _log.d('file missing, clear localData: $messageId');
        await _store.updateLocalData(messageId, null);
      } catch (e) {
        _log.w('parse localData failed: $e');
        await _store.updateLocalData(messageId, null);
      }
    }

    // 2. URL 去重：同一 URL 共享 Completer
    if (_downloading.containsKey(url)) {
      _log.d('dedup: $url already downloading');
      return _downloading[url]!.future;
    }

    // 3. 创建任务
    final Completer<String> completer = Completer<String>();
    _downloading[url] = completer;

    final _DownloadTask task = _DownloadTask(
      url: url,
      messageId: messageId,
      category: category,
      fileName: fileName,
      onProgress: onProgress,
      completer: completer,
    );

    // 4. 并发控制
    if (_activeCount < maxConcurrent) {
      _startDownload(task);
    } else {
      _log.d('queue: $url (active=$_activeCount)');
      _queue.add(task);
    }

    return completer.future;
  }

  @override
  Future<void> markLocal({
    required String messageId,
    required String localPath,
  }) async {
    final String json = jsonEncode({
      'path': localPath,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    });
    await _store.updateLocalData(messageId, json);
    _log.d('markLocal: $messageId → $localPath');
  }

  @override
  Future<void> clearCache(String messageId) async {
    final String? data = await _store.getLocalData(messageId);
    if (data != null) {
      try {
        final Map<String, dynamic> parsed =
            jsonDecode(data) as Map<String, dynamic>;
        final String path = parsed['path'] as String;
        final File file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
          _log.d('deleted: $path');
        }
      } catch (_) {}
    }
    await _store.updateLocalData(messageId, null);
  }

  @override
  void dispose() {
    _queue.clear();
  }

  // ─── 内部方法 ───

  Future<void> _startDownload(_DownloadTask task) async {
    _activeCount++;
    _log.d('start: ${task.url} (active=$_activeCount)');

    try {
      final String savePath =
          _buildSavePath(task.messageId, task.category, task.url, task.fileName);

      // 确保目录存在
      final Directory dir = File(savePath).parent;
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      await _download(task.url, savePath, onProgress: task.onProgress);

      // 写 localData
      final String localDataJson = jsonEncode({
        'path': savePath,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      });
      await _store.updateLocalData(task.messageId, localDataJson);

      _log.d('done: ${task.messageId} → $savePath');
      task.completer.complete(savePath);
    } catch (e) {
      _log.w('download failed: ${task.url}, error=$e');
      task.completer.completeError(e);
    } finally {
      _downloading.remove(task.url);
      _activeCount--;
      _processQueue();
    }
  }

  void _processQueue() {
    while (_queue.isNotEmpty && _activeCount < maxConcurrent) {
      final _DownloadTask next = _queue.removeFirst();
      _startDownload(next);
    }
  }

  String _buildSavePath(
      String messageId, FileCategory category, String url, String? fileName) {
    String ext = '';
    if (fileName != null && fileName.contains('.')) {
      ext = fileName.substring(fileName.lastIndexOf('.'));
    } else if (url.contains('.')) {
      final String urlPath = url.split('?').first;
      if (urlPath.contains('.')) {
        ext = urlPath.substring(urlPath.lastIndexOf('.'));
      }
    }
    // 默认扩展名
    if (ext.isEmpty) {
      ext = switch (category) {
        FileCategory.image => '.jpg',
        FileCategory.video => '.mp4',
        FileCategory.audio => '.m4a',
        FileCategory.file => '.bin',
      };
    }
    return p.join(_baseDir, category.name, '$messageId$ext');
  }
}
