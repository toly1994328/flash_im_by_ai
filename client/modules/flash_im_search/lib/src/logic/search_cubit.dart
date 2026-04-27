import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/search_models.dart';
import '../data/search_repository.dart';
import 'search_state.dart';

/// 综合搜索 Cubit
///
/// 300ms 防抖，并发调用三个搜索接口，各自独立 try-catch。
class SearchCubit extends Cubit<SearchState> {
  final SearchRepository _repository;
  Timer? _debounceTimer;

  SearchCubit(this._repository) : super(SearchInitial());

  /// 触发搜索（300ms 防抖）
  void search(String keyword) {
    _debounceTimer?.cancel();
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      emit(SearchInitial());
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _doSearch(trimmed);
    });
  }

  /// 清空搜索
  void clear() {
    _debounceTimer?.cancel();
    emit(SearchInitial());
  }

  Future<void> _doSearch(String keyword) async {
    emit(SearchLoading());

    List<FriendSearchItem> friends = [];
    List<GroupSearchItem> groups = [];
    List<MessageSearchGroup> messageGroups = [];
    String? friendError;
    String? groupError;
    String? messageError;

    final results = await Future.wait([
      _repository.searchFriends(keyword: keyword).then<Object?>((v) => v).catchError((e) => e),
      _repository.searchJoinedGroups(keyword: keyword).then<Object?>((v) => v).catchError((e) => e),
      _repository.searchMessages(keyword: keyword).then<Object?>((v) => v).catchError((e) => e),
    ]);

    if (results[0] is List<FriendSearchItem>) {
      friends = results[0] as List<FriendSearchItem>;
    } else {
      friendError = results[0].toString();
    }

    if (results[1] is List<GroupSearchItem>) {
      groups = results[1] as List<GroupSearchItem>;
    } else {
      groupError = results[1].toString();
    }

    if (results[2] is List<MessageSearchGroup>) {
      messageGroups = results[2] as List<MessageSearchGroup>;
    } else {
      messageError = results[2].toString();
    }

    final result = SearchResult(
      friends: friends,
      groups: groups,
      messageGroups: messageGroups,
      friendError: friendError,
      groupError: groupError,
      messageError: messageError,
    );

    if (result.allSuccess) {
      emit(SearchSuccess(result));
    } else {
      emit(SearchPartialSuccess(result));
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
