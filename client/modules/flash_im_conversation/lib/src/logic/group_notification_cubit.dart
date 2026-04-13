import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_im_core/flash_im_core.dart';
import '../data/conversation_repository.dart';

/// 群通知状态
class GroupNotificationState {
  final int pendingCount;
  const GroupNotificationState({this.pendingCount = 0});
}

/// 群通知 Cubit — 跟踪待处理入群申请数量
class GroupNotificationCubit extends Cubit<GroupNotificationState> {
  final ConversationRepository _repository;
  StreamSubscription? _wsSub;

  GroupNotificationCubit({
    required ConversationRepository repository,
    WsClient? wsClient,
  })  : _repository = repository,
        super(const GroupNotificationState()) {
    _wsSub = wsClient?.groupJoinRequestStream.listen((_) => refresh());
  }

  Future<void> load() async {
    try {
      final requests = await _repository.getMyJoinRequests();
      final count = requests.where((r) => r.status == 0).length;
      emit(GroupNotificationState(pendingCount: count));
    } catch (_) {
      emit(const GroupNotificationState(pendingCount: 0));
    }
  }

  Future<void> refresh() async => load();

  void decrementCount() {
    if (state.pendingCount > 0) {
      emit(GroupNotificationState(pendingCount: state.pendingCount - 1));
    }
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
