import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fx_logger/fx_logger.dart';

import '../data/subscription_repository.dart';

/// 全局订阅状态管理
class SubscriptionCubit extends Cubit<SubscriptionStatus> {
  static final FxLog _log = FxLog('Sub');
  final SubscriptionRepository _repository;

  SubscriptionCubit({required SubscriptionRepository repository})
      : _repository = repository,
        super(const SubscriptionStatus.empty());

  /// 是否可以走 OSS 上传
  bool get ossUploadEnabled => state.ossUploadEnabled;

  /// 登录后查询订阅状态
  Future<void> loadStatus() async {
    try {
      final SubscriptionStatus status = await _repository.getStatus();
      emit(status);
      _log.d('loadStatus: active=${status.hasActiveSubscription}, oss=${status.ossUploadEnabled}');
    } catch (e) {
      _log.e('loadStatus failed', error: e);
      // 查询失败保持空状态，不影响正常使用
    }
  }

  /// 兑换码激活
  Future<RedeemResult> redeem(String code) async {
    final RedeemResult result = await _repository.redeem(code);
    // 兑换成功后刷新状态
    await loadStatus();
    return result;
  }
}
