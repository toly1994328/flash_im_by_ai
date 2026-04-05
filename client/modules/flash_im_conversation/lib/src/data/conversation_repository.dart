import 'package:dio/dio.dart';
import 'conversation.dart';

/// 会话 API 调用
class ConversationRepository {
  final Dio _dio;

  ConversationRepository({required Dio dio}) : _dio = dio;

  /// 获取会话列表（分页）
  Future<List<Conversation>> getList({int limit = 20, int offset = 0}) async {
    final res = await _dio.get('/conversations', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    final List data = res.data as List;
    return data
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 创建私聊会话
  Future<Conversation> createPrivate(int peerUserId) async {
    final res = await _dio.post('/conversations', data: {
      'peer_user_id': peerUserId,
    });
    return Conversation.fromJson(res.data as Map<String, dynamic>);
  }

  /// 删除会话
  Future<void> delete(String conversationId) async {
    await _dio.delete('/conversations/$conversationId');
  }

  /// 标记已读（重置未读数）
  Future<void> markRead(String conversationId) async {
    await _dio.post('/conversations/$conversationId/read');
  }

  /// 获取单个会话详情
  Future<Conversation> getById(String conversationId) async {
    final res = await _dio.get('/conversations/$conversationId');
    return Conversation.fromJson(res.data as Map<String, dynamic>);
  }
}
