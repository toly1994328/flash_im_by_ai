import 'package:dio/dio.dart';
import 'package:flash_im_cache/flash_im_cache.dart';
import 'conversation.dart';

/// 会话数据仓库
///
/// 读取优先本地（LocalStore），写入仍走 HTTP。
/// store 为 null 时 fallback 到 HTTP（向后兼容）。
class ConversationRepository {
  final Dio _dio;
  LocalStore? _store;

  ConversationRepository({required Dio dio}) : _dio = dio;

  /// 登录后注入本地存储
  void setStore(LocalStore store) => _store = store;

  /// 获取当前本地存储（供 Cubit 监听变更）
  LocalStore? get store => _store;

  /// 获取会话列表（分页）
  Future<List<Conversation>> getList({int limit = 20, int offset = 0, int? type}) async {
    if (_store != null) {
      final cached = await _store!.getConversations(limit: limit, offset: offset);
      if (cached.isNotEmpty) return cached.map(_fromCached).toList();
      // 本地为空（首次登录），fallback HTTP
    }
    final res = await _dio.get('/conversations', queryParameters: {
      'limit': limit,
      'offset': offset,
      if (type != null) 'type': type,
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
    if (_store != null) {
      final cached = await _store!.getConversation(conversationId);
      if (cached != null) return _fromCached(cached);
    }
    final res = await _dio.get('/conversations/$conversationId');
    return Conversation.fromJson(res.data as Map<String, dynamic>);
  }

  /// CachedConversation → Conversation
  Conversation _fromCached(CachedConversation c) {
    return Conversation(
      id: c.id,
      type: c.type,
      name: c.name,
      avatar: c.avatar,
      peerUserId: c.peerUserId,
      peerNickname: c.peerNickname,
      peerAvatar: c.peerAvatar,
      lastMessageAt: c.lastMessageAt != null
          ? DateTime.fromMillisecondsSinceEpoch(c.lastMessageAt!)
          : null,
      lastMessagePreview: c.lastMessagePreview,
      unreadCount: c.unreadCount,
      isPinned: c.isPinned,
      isMuted: c.isMuted,
      createdAt: DateTime.fromMillisecondsSinceEpoch(c.createdAt),
    );
  }
}
