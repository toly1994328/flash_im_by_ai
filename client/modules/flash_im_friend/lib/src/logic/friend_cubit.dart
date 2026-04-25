import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_im_core/flash_im_core.dart';
import '../data/friend.dart';
import '../data/friend_repository.dart';
import 'friend_state.dart';

class FriendCubit extends Cubit<FriendState> {
  final FriendRepository _repository;
  final WsClient _wsClient;
  StreamSubscription? _requestSub;
  StreamSubscription? _acceptedSub;
  StreamSubscription? _removedSub;
  StreamSubscription? _onlineSub;
  StreamSubscription? _offlineSub;
  StreamSubscription? _onlineListSub;

  FriendCubit({
    required FriendRepository repository,
    required WsClient wsClient,
  })  : _repository = repository,
        _wsClient = wsClient,
        super(const FriendState()) {
    _requestSub = _wsClient.friendRequestStream.listen(_handleFriendRequest);
    _acceptedSub = _wsClient.friendAcceptedStream.listen(_handleFriendAccepted);
    _removedSub = _wsClient.friendRemovedStream.listen(_handleFriendRemoved);
    _onlineSub = _wsClient.userOnlineStream.listen(_handleUserOnline);
    _offlineSub = _wsClient.userOfflineStream.listen(_handleUserOffline);
    _onlineListSub = _wsClient.onlineListStream.listen(_handleOnlineList);
    // 初始化在线状态（WsClient 可能已经收到过 ONLINE_LIST）
    if (_wsClient.onlineUserIds.isNotEmpty) {
      emit(state.copyWith(onlineIds: Set<String>.from(_wsClient.onlineUserIds)));
    }
  }

  Future<void> loadFriends() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final friends = await _repository.getFriends();
      emit(state.copyWith(friends: friends, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadReceivedRequests() async {
    try {
      final requests = await _repository.getReceivedRequests();
      emit(state.copyWith(receivedRequests: requests, pendingCount: requests.length));
    } catch (_) {}
  }

  Future<void> loadSentRequests() async {
    try {
      final requests = await _repository.getSentRequests();
      emit(state.copyWith(sentRequests: requests));
    } catch (_) {}
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      await _repository.acceptRequest(requestId);
      final updated = state.receivedRequests.where((r) => r.id != requestId).toList();
      emit(state.copyWith(
        receivedRequests: updated,
        pendingCount: (state.pendingCount - 1).clamp(0, 999),
      ));
      await loadFriends();
    } catch (_) {}
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      await _repository.rejectRequest(requestId);
      final updated = state.receivedRequests.where((r) => r.id != requestId).toList();
      emit(state.copyWith(
        receivedRequests: updated,
        pendingCount: (state.pendingCount - 1).clamp(0, 999),
      ));
    } catch (_) {}
  }

  Future<void> deleteFriend(String friendId) async {
    try {
      await _repository.deleteFriend(friendId);
      final updated = state.friends.where((f) => f.friendId != friendId).toList();
      emit(state.copyWith(friends: updated));
    } catch (_) {}
  }

  void clearPendingCount() {
    if (state.pendingCount > 0) {
      emit(state.copyWith(pendingCount: 0));
    }
  }

  Future<void> deleteRequest(String requestId) async {
    try {
      await _repository.deleteRequest(requestId);
      final updatedReceived = state.receivedRequests.where((r) => r.id != requestId).toList();
      final updatedSent = state.sentRequests.where((r) => r.id != requestId).toList();
      emit(state.copyWith(receivedRequests: updatedReceived, sentRequests: updatedSent));
    } catch (_) {}
  }

  void _handleFriendRequest(WsFrame frame) {
    try {
      final notification = FriendRequestNotification.fromBuffer(frame.payload);
      final request = FriendRequest(
        id: notification.requestId,
        fromUserId: notification.fromUserId,
        toUserId: '',
        message: notification.message.isEmpty ? null : notification.message,
        status: 0,
        nickname: notification.nickname,
        avatar: notification.avatar.isEmpty ? null : notification.avatar,
        createdAt: DateTime.fromMillisecondsSinceEpoch(notification.createdAt.toInt()),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(notification.createdAt.toInt()),
      );
      emit(state.copyWith(
        receivedRequests: [request, ...state.receivedRequests],
        pendingCount: state.pendingCount + 1,
      ));
    } catch (_) {}
  }

  void _handleFriendAccepted(WsFrame frame) {
    try {
      final notification = FriendAcceptedNotification.fromBuffer(frame.payload);
      final friend = Friend(
        friendId: notification.friendId,
        nickname: notification.nickname,
        avatar: notification.avatar.isEmpty ? null : notification.avatar,
        createdAt: DateTime.fromMillisecondsSinceEpoch(notification.createdAt.toInt()),
      );
      if (!state.friends.any((f) => f.friendId == friend.friendId)) {
        emit(state.copyWith(friends: [...state.friends, friend]));
      }
    } catch (_) {}
  }

  void _handleFriendRemoved(WsFrame frame) {
    try {
      final notification = FriendRemovedNotification.fromBuffer(frame.payload);
      final updated = state.friends.where((f) => f.friendId != notification.friendId).toList();
      emit(state.copyWith(friends: updated));
    } catch (_) {}
  }

  void _handleUserOnline(WsFrame frame) {
    try {
      final notif = UserStatusNotification.fromBuffer(frame.payload);
      final updated = Set<String>.from(state.onlineIds)..add(notif.userId);
      emit(state.copyWith(onlineIds: updated));
    } catch (_) {}
  }

  void _handleUserOffline(WsFrame frame) {
    try {
      final notif = UserStatusNotification.fromBuffer(frame.payload);
      final updated = Set<String>.from(state.onlineIds)..remove(notif.userId);
      emit(state.copyWith(onlineIds: updated));
    } catch (_) {}
  }

  void _handleOnlineList(WsFrame frame) {
    try {
      final notif = OnlineListNotification.fromBuffer(frame.payload);
      emit(state.copyWith(onlineIds: Set<String>.from(notif.userIds)));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _requestSub?.cancel();
    _acceptedSub?.cancel();
    _removedSub?.cancel();
    _onlineSub?.cancel();
    _offlineSub?.cancel();
    _onlineListSub?.cancel();
    return super.close();
  }
}
