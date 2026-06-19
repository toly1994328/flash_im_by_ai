import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fx_logger/fx_logger.dart';

import '../data/cloud_download_manager.dart';
import '../data/cloud_file.dart';
import '../data/cloud_repository.dart';

enum FileDetailStatus { loading, loaded, error, deleted }

class FileDetailState {
  final FileDetailStatus status;
  final CloudFileDetail? detail;
  final DownloadInfo downloadInfo;
  final String? error;

  const FileDetailState({
    this.status = FileDetailStatus.loading,
    this.detail,
    this.downloadInfo = const DownloadInfo(),
    this.error,
  });

  bool get isCached => downloadInfo.status == DownloadStatus.done;
  bool get isDownloading => downloadInfo.status == DownloadStatus.downloading;

  FileDetailState copyWith({
    FileDetailStatus? status,
    CloudFileDetail? detail,
    DownloadInfo? downloadInfo,
    String? error,
  }) {
    return FileDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      downloadInfo: downloadInfo ?? this.downloadInfo,
      error: error ?? this.error,
    );
  }
}

class FileDetailCubit extends Cubit<FileDetailState> {
  static final FxLog _log = FxLog('FileDetail');
  final CloudRepository _repository;
  final CloudDownloadManager _downloadManager = CloudDownloadManager();
  StreamSubscription<int>? _downloadSub;
  int? _fileId;

  FileDetailCubit({required CloudRepository repository})
      : _repository = repository,
        super(const FileDetailState()) {
    _downloadSub = _downloadManager.updateStream.listen(_onDownloadUpdate);
  }

  void _onDownloadUpdate(int fileId) {
    if (fileId != _fileId) return;
    final DownloadInfo info = _downloadManager.getStatus(fileId);
    emit(state.copyWith(downloadInfo: info));
  }

  /// 加载文件详情
  Future<void> loadDetail(int fileId) async {
    _fileId = fileId;
    emit(const FileDetailState(status: FileDetailStatus.loading));
    try {
      final CloudFileDetail detail = await _repository.getFileDetail(fileId);
      final DownloadInfo info = _downloadManager.getStatus(fileId);
      emit(FileDetailState(
        status: FileDetailStatus.loaded,
        detail: detail,
        downloadInfo: info,
      ));
    } catch (e) {
      _log.e('loadDetail failed', error: e);
      emit(FileDetailState(status: FileDetailStatus.error, error: e.toString()));
    }
  }

  /// 下载文件到本地
  void downloadToLocal() {
    if (state.detail == null || _fileId == null) return;
    _downloadManager.download(
      fileId: _fileId!,
      fileUrl: state.detail!.file.url,
      fileSize: state.detail!.file.size,
    );
  }

  /// 清除本地缓存
  Future<void> clearLocalCache() async {
    if (state.detail == null || _fileId == null) return;
    await _downloadManager.removeCache(_fileId!, state.detail!.file.url);
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
    return super.close();
  }
}
