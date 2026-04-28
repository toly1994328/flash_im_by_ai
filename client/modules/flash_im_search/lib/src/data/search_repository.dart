import 'package:dio/dio.dart';
import 'search_models.dart';

/// 搜索数据仓库，封装所有搜索相关 HTTP 请求
class SearchRepository {
  final Dio _dio;

  SearchRepository({required Dio dio}) : _dio = dio;

  /// 搜索好友
  Future<List<FriendSearchItem>> searchFriends({
    required String keyword,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      '/api/friends/search',
      queryParameters: {'keyword': keyword, 'limit': limit},
    );
    final List data = res.data['data'] as List;
    return data
        .map((e) => FriendSearchItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 搜索已加入的群聊
  Future<List<GroupSearchItem>> searchJoinedGroups({
    required String keyword,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      '/api/conversations/search-joined-groups',
      queryParameters: {'keyword': keyword, 'limit': limit},
    );
    final List data = res.data['data'] as List;
    return data
        .map((e) => GroupSearchItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 搜索消息（按会话分组）
  Future<List<MessageSearchGroup>> searchMessages({
    required String keyword,
    int limit = 10,
  }) async {
    final res = await _dio.get(
      '/api/messages/search',
      queryParameters: {'keyword': keyword, 'limit': limit},
    );
    final List data = res.data['data'] as List;
    return data
        .map((e) => MessageSearchGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 会话内搜索消息
  Future<List<MessageSearchItem>> searchConversationMessages({
    required String conversationId,
    required String keyword,
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/conversations/$conversationId/messages/search',
      queryParameters: {'keyword': keyword, 'limit': limit, 'offset': offset},
    );
    final List data = res.data['data'] as List;
    return data
        .map((e) => MessageSearchItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
