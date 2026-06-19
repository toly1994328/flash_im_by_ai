import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fx_logger/fx_logger.dart';

import '../data/cloud_file.dart';
import '../data/cloud_repository.dart';

enum CloudFileStatus { initial, loading, loaded, loadingMore, error }

class CloudFileState {
  final CloudFileStatus status;
  final List<CloudFile> files;
  final int total;
  final int page;
  final String category;
  final String? error;

  const CloudFileState({
    this.status = CloudFileStatus.initial,
    this.files = const [],
    this.total = 0,
    this.page = 1,
    this.category = 'all',
    this.error,
  });

  bool get hasMore => files.length < total;

  CloudFileState copyWith({
    CloudFileStatus? status,
    List<CloudFile>? files,
    int? total,
    int? page,
    String? category,
    String? error,
  }) {
    return CloudFileState(
      status: status ?? this.status,
      files: files ?? this.files,
      total: total ?? this.total,
      page: page ?? this.page,
      category: category ?? this.category,
      error: error ?? this.error,
    );
  }
}

class CloudFileCubit extends Cubit<CloudFileState> {
  static final FxLog _log = FxLog('CloudFile');
  final CloudRepository _repository;
  static const int _pageSize = 20;

  CloudFileCubit({required CloudRepository repository})
      : _repository = repository,
        super(const CloudFileState());

  /// 加载文件列表（重置分页）
  Future<void> loadFiles({String category = 'all'}) async {
    emit(state.copyWith(status: CloudFileStatus.loading, category: category, page: 1));
    try {
      final String? apiCategory = category == 'all' ? null : category;
      final (List<CloudFile> files, int total) = await _repository.getFiles(
        category: apiCategory,
        page: 1,
        limit: _pageSize,
      );
      emit(state.copyWith(
        status: CloudFileStatus.loaded,
        files: files,
        total: total,
        page: 1,
      ));
    } catch (e) {
      _log.e('loadFiles failed', error: e);
      emit(state.copyWith(status: CloudFileStatus.error, error: e.toString()));
    }
  }

  /// 加载更多（下一页）
  Future<void> loadMore() async {
    if (!state.hasMore || state.status == CloudFileStatus.loadingMore) return;
    final int nextPage = state.page + 1;
    emit(state.copyWith(status: CloudFileStatus.loadingMore));
    try {
      final String? apiCategory = state.category == 'all' ? null : state.category;
      final (List<CloudFile> files, int total) = await _repository.getFiles(
        category: apiCategory,
        page: nextPage,
        limit: _pageSize,
      );
      emit(state.copyWith(
        status: CloudFileStatus.loaded,
        files: [...state.files, ...files],
        total: total,
        page: nextPage,
      ));
    } catch (e) {
      _log.e('loadMore failed', error: e);
      emit(state.copyWith(status: CloudFileStatus.loaded));
    }
  }

  /// 切换分类
  void switchCategory(String category) {
    if (category == state.category) return;
    loadFiles(category: category);
  }

  /// 从列表中移除某文件（删除后调用）
  void removeFile(int fileId) {
    final List<CloudFile> updated = state.files.where((f) => f.id != fileId).toList();
    emit(state.copyWith(files: updated, total: state.total - 1));
  }
}
