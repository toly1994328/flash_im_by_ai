import '../data/search_models.dart';

/// 搜索状态
sealed class SearchState {}

/// 初始状态（显示搜索历史）
final class SearchInitial extends SearchState {}

/// 搜索中
final class SearchLoading extends SearchState {}

/// 搜索成功（三个接口全部成功）
final class SearchSuccess extends SearchState {
  final SearchResult result;
  SearchSuccess(this.result);
}

/// 部分成功（至少一个接口失败，但有结果）
final class SearchPartialSuccess extends SearchState {
  final SearchResult result;
  SearchPartialSuccess(this.result);
}
