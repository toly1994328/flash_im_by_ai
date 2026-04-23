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
  StreamSubscription? _groupInfoSub;

  ConversationListCubit(this._repository, {WsClient? wsClient})
      : _wsClient = wsClient,
        super(const ConversationListInitial()) {
    _updateSub = _wsClient?.conversationUpdateStream.listen(_handleUpdate);
    _groupInfoSub = _wsClient?.groupInfoUpdateStream.listen(_handleGroupInfoUpdate);
  }

  void _handleUpdate(WsFrame frame) {
    try {
      final update = ConversationUpdate.fromBuffer(frame.payload);
      final current = state;
      if (current is! ConversationListLoaded) return;

      final found = current.conversations.any((c) => c.id == update.conversationId);

      if (!found) {
        // 未知会话：先插入骨架，再异步补全
        final skeleton = Conversation.skeleton(
          id: update.conversationId,
          lastMessagePreview: update.lastMessagePreview,
          lastMessageAt: DateTime.fromMillisecondsSinceEpoch(update.lastMessageAt.toInt()),
          unreadCount: update.unreadCount,
        );
        final updated = [skeleton, ...current.conversations];
        emit(ConversationListLoaded(
          updated,
          hasMore: current.hasMore,
          totalUnread: update.totalUnread,
        ));
        // 异步拉取完整信息替换骨架
        _repository.getById(update.conversationId).then((full) {
          final s = state;
          if (s is! ConversationListLoaded) return;
          final replaced = s.conversations.map((c) {
            if (c.id == full.id) return full.copyWith(unreadCount: c.unreadCount);
            return c;
          }).toList();
          emit(ConversationListLoaded(replaced, hasMore: s.hasMore, totalUnread: s.totalUnread));
        }).catchError((_) {});
        return;
      }

      final updated = current.conversations.map((c) {
        if (c.id == update.conversationId) {
          return Conversation(
            id: c.id,
            type: c.type,
            name: c.name,
            avatar: c.avatar,
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

  /// 进入聊天页时清除该会话的未读数
  void clearUnread(String conversationId) {
    final current = state;
    if (current is! ConversationListLoaded) return;
    final idx = current.conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;
    final conv = current.conversations[idx];
    if (conv.unreadCount == 0) return;
    final delta = conv.unreadCount;
    final updated = current.conversations.map((c) {
      if (c.id == conversationId) return c.copyWith(unreadCount: 0);
      return c;
    }).toList();
    emit(ConversationListLoaded(
      updated,
      hasMore: current.hasMore,
      totalUnread: (current.totalUnread - delta).clamp(0, 999999),
    ));
    // 通知后端
    _repository.markRead(conversationId).catchError((_) {});
  }

  void _handleGroupInfoUpdate(WsFrame frame) {
    try {
      final update = GroupInfoUpdate.fromBuffer(frame.payload);
      final current = state;
      if (current is! ConversationListLoaded) return;

      final updated = current.conversations.map((c) {
        if (c.id == update.conversationId) {
          return Conversation(
            id: c.id,
            type: c.type,
            name: update.hasName() ? update.name : c.name,
            avatar: update.hasAvatar() ? update.avatar : c.avatar,
            peerUserId: c.peerUserId,
            peerNickname: c.peerNickname,
            peerAvatar: c.peerAvatar,
            lastMessageAt: c.lastMessageAt,
            lastMessagePreview: c.lastMessagePreview,
            unreadCount: c.unreadCount,
            isPinned: c.isPinned,
            isMuted: c.isMuted,
            createdAt: c.createdAt,
          );
        }
        return c;
      }).toList();

      emit(ConversationListLoaded(updated, hasMore: current.hasMore, totalUnread: current.totalUnread));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _updateSub?.cancel();
    _groupInfoSub?.cancel();
    return super.close();
  }
}
