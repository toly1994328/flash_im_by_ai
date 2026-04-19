import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/group_repository.dart';

/// 群通知状态
class GroupNotificationState {
  final int pendingCount;
  final bool isLoading;

  const GroupNotificationState({this.pendingCount = 0, this.isLoading = false});

  GroupNotificationState copyWith({int? pendingCount, bool? isLoading}) {
    return GroupNotificationState(
      pendingCount: pendingCount ?? this.pendingCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 群通知 Cubit（应用级）
///
/// 监听 WS 推送的 GROUP_JOIN_REQUEST 帧驱动 pendingCount，
/// 通讯录 Tab 根据 pendingCount > 0 显示红点角标。
class GroupNotificationCubit extends Cubit<GroupNotificationState> {
  final GroupRepository _repository;
  StreamSubscription? _subscription;

  GroupNotificationCubit({
    required GroupRepository repository,
    required Stream<dynamic> groupJoinRequestStream,
  })  : _repository = repository,
        super(const GroupNotificationState()) {
    _subscription = groupJoinRequestStream.listen((_) {
      emit(state.copyWith(pendingCount: state.pendingCount + 1));
    });
  }

  /// 从服务端加载待处理申请数量
  Future<void> loadPendingCount() async {
    try {
      final requests = await _repository.getJoinRequests();
      final count = requests.where((r) => r.status == 0).length;
      emit(state.copyWith(pendingCount: count));
    } catch (_) {
      // 加载失败不影响使用
    }
  }

  /// 审批后减少计数
  void decrementCount() {
    final newCount = state.pendingCount > 0 ? state.pendingCount - 1 : 0;
    emit(state.copyWith(pendingCount: newCount));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
