import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/conversation_repository.dart';
import '../data/conversation.dart';
import 'conversation_list_state.dart';

/// 会话列表状态管理（支持分页）
class ConversationListCubit extends Cubit<ConversationListState> {
  final ConversationRepository _repository;
  static const int _pageSize = 20;
  bool _isLoadingMore = false;

  ConversationListCubit(this._repository)
      : super(const ConversationListInitial());

  /// 加载会话列表（首页）
  Future<void> loadConversations() async {
    _isLoadingMore = false;
    emit(const ConversationListLoading());
    try {
      final conversations = await _repository.getList(limit: _pageSize, offset: 0);
      final hasMore = conversations.length >= _pageSize;
      print('[ConversationList] ${DateTime.now()} loaded ${conversations.length} conversations, hasMore=$hasMore');
      emit(ConversationListLoaded(conversations, hasMore: hasMore));
    } catch (e) {
      print('[ConversationList] ${DateTime.now()} load failed: $e');
      emit(ConversationListError(e.toString()));
    }
  }

  /// 加载更多
  Future<void> loadMore() async {
    final current = state;
    if (current is! ConversationListLoaded || !current.hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    try {
      final offset = current.conversations.length;
      print('[ConversationList] ${DateTime.now()} loading more, offset=$offset');
      final more = await _repository.getList(
        limit: _pageSize,
        offset: offset,
      );
      final hasMore = more.length >= _pageSize;
      final all = [...current.conversations, ...more];
      print('[ConversationList] ${DateTime.now()} loaded ${more.length} more, total=${all.length}, hasMore=$hasMore');
      emit(ConversationListLoaded(all, hasMore: hasMore));
    } catch (e) {
      print('[ConversationList] ${DateTime.now()} loadMore failed: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  /// 删除会话
  Future<void> deleteConversation(String id) async {
    try {
      await _repository.delete(id);
      final current = state;
      if (current is ConversationListLoaded) {
        final updated = current.conversations.where((c) => c.id != id).toList();
        emit(ConversationListLoaded(updated, hasMore: current.hasMore));
      }
    } catch (_) {}
  }
}
