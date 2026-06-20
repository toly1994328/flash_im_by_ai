import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fx_logger/fx_logger.dart';
import 'package:fx_media/fx_media.dart';

import '../data/cloud_file.dart';
import '../data/cloud_repository.dart';

enum FileDetailStatus { loading, loaded, error, deleted }

class FileDetailState {
  final FileDetailStatus status;
  final CloudFileDetail? detail;
  final double downloadProgress;
  final String? localPath;
  final bool isDownloading;
  final String? error;

  const FileDetailState({
    this.status = FileDetailStatus.loading,
    this.detail,
    this.downloadProgress = 0.0,
    this.localPath,
    this.isDownloading = false,
    this.error,
  });

  bool get isCached => localPath != null;

  FileDetailState copyWith({
    FileDetailStatus? status,
    CloudFileDetail? detail,
    double? downloadProgress,
    Object? localPath = _sentinel,
    bool? isDownloading,
    String? error,
  }) {
    return FileDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      localPath: localPath == _sentinel ? this.localPath : localPath as String?,
      isDownloading: isDownloading ?? this.isDownloading,
      error: error ?? this.error,
    );
  }
}

const Object _sentinel = Object();

class FileDetailCubit extends Cubit<FileDetailState> {
  static final FxLog _log = FxLog('FileDetail');
  final CloudRepository _repository;
  final String? _baseUrl;
  StreamSubscription<FxDownloadEvent>? _downloadSub;
  int? _fileId;

  FileDetailCubit({required CloudRepository repository, String? baseUrl})
      : _repository = repository,
        _baseUrl = baseUrl,
        super(const FileDetailState());

  String _resolveUrl(String url) {
    if (url.startsWith('http')) return url;
    if (_baseUrl != null) return '$_baseUrl$url';
    return url;
  }

  /// 加载文件详情
  Future<void> loadDetail(int fileId) async {
    _fileId = fileId;
    emit(const FileDetailState(status: FileDetailStatus.loading));
    try {
      final CloudFileDetail detail = await _repository.getFileDetail(fileId);
      final String cacheId = fxMediaIdFromUrl(detail.file.url);
      final String? cached = FxMedia.download.localPath(cacheId);
      _log.d('loadDetail: fileId=$fileId, url=${detail.file.url}, cacheId=$cacheId, cached=$cached');
      emit(FileDetailState(
        status: FileDetailStatus.loaded,
        detail: detail,
        localPath: cached,
      ));
    } catch (e) {
      _log.e('loadDetail failed', error: e);
      emit(FileDetailState(status: FileDetailStatus.error, error: e.toString()));
    }
  }

  /// 下载文件到本地
  void downloadToLocal() {
    if (state.detail == null || _fileId == null) return;
    final String fullUrl = _resolveUrl(state.detail!.file.url);
    final String cacheId = fxMediaIdFromUrl(state.detail!.file.url);

    emit(state.copyWith(isDownloading: true, downloadProgress: 0.0));

    _downloadSub?.cancel();
    _downloadSub = FxMedia.download.stream(url: fullUrl, id: cacheId).listen((FxDownloadEvent event) {
      switch (event) {
        case FxDownloadProgress(:final double progress):
          emit(state.copyWith(downloadProgress: progress));
        case FxDownloadComplete(:final String localPath):
          emit(state.copyWith(isDownloading: false, downloadProgress: 1.0, localPath: localPath));
        case FxDownloadError(:final Object error):
          emit(state.copyWith(isDownloading: false, error: error.toString()));
      }
    });
  }

  /// 清除本地缓存
  Future<void> clearLocalCache() async {
    if (state.detail == null) return;
    final String cacheId = fxMediaIdFromUrl(state.detail!.file.url);
    await FxMedia.download.remove(cacheId);
    emit(state.copyWith(localPath: null));
  }

  /// 删除云端文件
  Future<void> deleteFile(int fileId) async {
    try {
      await _repository.deleteFile(fileId);
      emit(state.copyWith(status: FileDetailStatus.deleted));
    } catch (e) {
      _log.e('deleteFile failed', error: e);
    }
  }

  @override
  Future<void> close() {
    _downloadSub?.cancel();
    // 退出详情页时，如果正在播放本页的音频则停止
    if (state.detail != null) {
      final String cacheId = fxMediaIdFromUrl(state.detail!.file.url);
      if (FxMedia.audio.currentId == cacheId) {
        FxMedia.audio.stop();
      }
    }
    return super.close();
  }
}
