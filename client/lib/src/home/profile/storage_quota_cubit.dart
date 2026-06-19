import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_im_core/flash_im_core.dart';
import 'package:fx_logger/fx_logger.dart';

import 'storage_repository.dart';

enum StorageQuotaStatus { initial, loading, loaded, error }

class StorageQuotaState {
  final StorageQuotaStatus status;
  final StorageQuota? quota;
  final String? error;

  const StorageQuotaState({
    this.status = StorageQuotaStatus.initial,
    this.quota,
    this.error,
  });

  StorageQuotaState copyWith({
    StorageQuotaStatus? status,
    StorageQuota? quota,
    String? error,
  }) {
    return StorageQuotaState(
      status: status ?? this.status,
      quota: quota ?? this.quota,
      error: error ?? this.error,
    );
  }
}

class StorageQuotaCubit extends Cubit<StorageQuotaState> {
  static final FxLog _log = FxLog('StorageQuota');
  final StorageRepository _repository;
  final WsClient? _wsClient;
  StreamSubscription<WsFrame>? _wsSub;

  StorageQuotaCubit({
    required StorageRepository repository,
    WsClient? wsClient,
  })  : _repository = repository,
        _wsClient = wsClient,
        super(const StorageQuotaState()) {
    _listenWs();
  }

  void _listenWs() {
    _wsSub = _wsClient?.storageQuotaStream.listen((WsFrame frame) {
      // payload 是 StorageQuotaNotification protobuf
      // 简化解析：前 8 bytes = used_bytes (varint field 1), 后 8 bytes = quota_bytes (varint field 2)
      // 直接重新拉取更精准
      _log.d('received storage quota update via WS');
      loadQuota();
    });
  }

  Future<void> loadQuota() async {
    emit(state.copyWith(status: StorageQuotaStatus.loading));
    try {
      final StorageQuota quota = await _repository.getQuota();
      emit(state.copyWith(status: StorageQuotaStatus.loaded, quota: quota));
    } catch (e) {
      _log.e('loadQuota failed', error: e);
      emit(state.copyWith(status: StorageQuotaStatus.error, error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
