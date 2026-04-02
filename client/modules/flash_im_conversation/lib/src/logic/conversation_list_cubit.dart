import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_im_core/flash_im_core.dart';
import '../data/conversation_repository.dart';
import '../data/conversation.dart';
import 'conversation_list_state.dart';

/// 会话列表状态管理（支持分页 + 实时更新）
class ConversationListCubit extends Cubit<ConversationListState> {
  final ConversationRepository _repository;
  final WsClient? _wsClient;
  static const int _pageSize = 20;
  bool _isLoadingMore = false;
  StreamSubscription? _updateSub;

  ConversationListCubit(this._repository, {WsClient? wsClient})
      : _wsClient = wsClient,
        super(const ConversationListInitial()) {
    _updateSub = _wsClient?.conversationUpdateStream.listen(_handleUpdate);
  }

  void _handleUpdate(WsFrame frame) {
    try {
      final update = ConversationUpdate.fromBuffer(frame.payload);
      final current = state;
      if (current is! ConversationListLoaded) return;

      final updated = current.conversations.map((c) {
        if (c.id == update.conversationId) {
          return Conversation(
            id: c.id,
            type: c.type,
            name: c.name,
            peerUserId: c.peerUserId,
            peerNickname: c.peerNickname,
            peerAvatar: c.peerAvatar,
            lastMessageAt: DateTime.fromMillisecondsSinceEpoch(update.lastMessageAt.toInt()),
            lastMessagePreview: update.lastMessagePreview,
            unreadCount: c.unreadCount + update.unreadCount,
            isPinned: c.isPinned,
            isMuted: c.isMuted,
            createdAt: c.createdAt,
          );
        }
        return c;
      }).toList();

      // 按 lastMessageAt 倒序排列
      updated.sort((a, b) {
        final aTime = a.lastMessageAt ?? a.createdAt;
        final bTime = b.lastMessageAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      emit(ConversationListLoaded(
        updated,
        hasMore: current.hasMore,
        totalUnread: update.totalUnread,
      ));
    } catch (_) {}
  }

  Future<void> loadConversations() async {
    _isLoadingMore = false;
    emit(const ConversationListLoading());
    try {
      final conversations = await _repository.getList(limit: _pageSize, offset: 0);
      final hasMore = conversations.length >= _pageSize;
      emit(ConversationListLoaded(conversations, hasMore: hasMore));
    } catch (e) {
      emit(ConversationListError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! ConversationListLoaded || !current.hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    try {
      final offset = current.conversations.length;
      final more = await _repository.getList(limit: _pageSize, offset: offset);
      final hasMore = more.length >= _pageSize;
      final all = [...current.conversations, ...more];
      emit(ConversationListLoaded(all, hasMore: hasMore, totalUnread: current.totalUnread));
    } catch (_) {
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      await _repository.delete(id);
      final current = state;
      if (current is ConversationListLoaded) {
        final updated = current.conversations.where((c) => c.id != id).toList();
        emit(ConversationListLoaded(updated, hasMore: current.hasMore, totalUnread: current.totalUnread));
      }
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _updateSub?.cancel();
    return super.close();
  }
}
