import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fx_logger/fx_logger.dart';
import 'package:path_provider/path_provider.dart';

enum DownloadStatus { idle, downloading, done, error }

class DownloadInfo {
  final DownloadStatus status;
  final double progress;
  final String? localPath;

  const DownloadInfo({
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.localPath,
  });
}

/// 全局云空间下载管理器（单例）
///
/// 管理文件下载队列，暴露 Stream 供多页面监听进度。
class CloudDownloadManager {
  static final FxLog _log = FxLog('CloudDL');

  static final CloudDownloadManager _instance = CloudDownloadManager._();
  factory CloudDownloadManager() => _instance;
  CloudDownloadManager._();

  Dio? _dio;
  String? _baseUrl;

  /// 初始化（app 启动时调用一次）
  void init({required Dio dio, required String baseUrl}) {
    _dio = dio;
    _baseUrl = baseUrl;
  }

  /// fileId → 下载信息
  final Map<int, DownloadInfo> _downloads = {};

  /// 进度变更通知流
  final StreamController<int> _updateController = StreamController<int>.broadcast();
  Stream<int> get updateStream => _updateController.stream;

  /// 获取某文件的下载状态
  DownloadInfo getStatus(int fileId) => _downloads[fileId] ?? const DownloadInfo();

  /// 是否正在下载
  bool isDownloading(int fileId) => _downloads[fileId]?.status == DownloadStatus.downloading;

  /// 是否已缓存
  bool isCached(int fileId) => _downloads[fileId]?.status == DownloadStatus.done;

  /// 触发下载
  Future<void> download({required int fileId, required String fileUrl, int? fileSize}) async {
    if (isDownloading(fileId) || isCached(fileId)) return;

    final String url = fileUrl.startsWith('http') ? fileUrl : '$_baseUrl$fileUrl';
    final String fileName = fileUrl.split('/').last;

    _downloads[fileId] = const DownloadInfo(status: DownloadStatus.downloading, progress: 0.0);
    _updateController.add(fileId);

    try {
      final Directory dir = await getApplicationCacheDirectory();
      final Directory cacheDir = Directory('${dir.path}/cloud_cache');
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);
      final String savePath = '${cacheDir.path}/$fileName';

      _log.d('downloading: fileId=$fileId url=$url -> $savePath');
      await _dio!.download(url, savePath, onReceiveProgress: (int count, int total) {
        final int effectiveTotal = total > 0 ? total : (fileSize ?? -1);
        final double progress = effectiveTotal > 0 ? (count / effectiveTotal).clamp(0.0, 1.0) : 0.0;
        _downloads[fileId] = DownloadInfo(
          status: DownloadStatus.downloading,
          progress: progress,
        );
        _updateController.add(fileId);
      });

      _downloads[fileId] = DownloadInfo(status: DownloadStatus.done, progress: 1.0, localPath: savePath);
      _updateController.add(fileId);
      _log.d('download done: fileId=$fileId path=$savePath');
    } catch (e) {
      _downloads[fileId] = const DownloadInfo(status: DownloadStatus.error);
      _updateController.add(fileId);
      _log.e('download failed: fileId=$fileId', error: e);
    }
  }

  /// 移除缓存记录（清除本地缓存后调用）
  Future<void> removeCache(int fileId, String fileUrl) async {
    final String fileName = fileUrl.split('/').last;
    final Directory dir = await getApplicationCacheDirectory();
    final File file = File('${dir.path}/cloud_cache/$fileName');
    if (await file.exists()) await file.delete();
    _downloads.remove(fileId);
    _updateController.add(fileId);
    _log.d('cache removed: fileId=$fileId');
  }

  /// 启动时扫描已缓存的文件（可选，按需调用）
  Future<void> scanExistingCache(List<int> fileIds, List<String> fileUrls) async {
    final Directory dir = await getApplicationCacheDirectory();
    final Directory cacheDir = Directory('${dir.path}/cloud_cache');
    if (!await cacheDir.exists()) return;

    for (int i = 0; i < fileIds.length; i++) {
      final String fileName = fileUrls[i].split('/').last;
      final File file = File('${cacheDir.path}/$fileName');
      if (await file.exists()) {
        _downloads[fileIds[i]] = DownloadInfo(status: DownloadStatus.done, progress: 1.0, localPath: file.path);
      }
    }
  }

  void dispose() {
    _updateController.close();
  }
}
