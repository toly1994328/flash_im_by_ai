import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_im_core/flash_im_core.dart' show WsClient, WsFrame, UserStatusNotification;

/// 对端用户在线状态管理（单聊场景）
class PeerStatusCubit extends Cubit<bool> {
  final String peerUserId;
  final WsClient _wsClient;
  StreamSubscription? _onlineSub;
  StreamSubscription? _offlineSub;

  PeerStatusCubit({
    required this.peerUserId,
    required WsClient wsClient,
  })  : _wsClient = wsClient,
        super(wsClient.isUserOnline(peerUserId)) {
    _onlineSub = _wsClient.userOnlineStream.listen(_onOnline);
    _offlineSub = _wsClient.userOfflineStream.listen(_onOffline);
  }

  void _onOnline(WsFrame frame) {
    final UserStatusNotification notif = UserStatusNotification.fromBuffer(frame.payload);
    if (notif.userId == peerUserId) emit(true);
  }

  void _onOffline(WsFrame frame) {
    final UserStatusNotification notif = UserStatusNotification.fromBuffer(frame.payload);
    if (notif.userId == peerUserId) emit(false);
  }

  @override
  Future<void> close() {
    _onlineSub?.cancel();
    _offlineSub?.cancel();
    return super.close();
  }
}
