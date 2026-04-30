import 'package:dio/dio.dart';
import 'package:flash_im_cache/flash_im_cache.dart';
import 'friend.dart';

class FriendRepository {
  final Dio _dio;
  LocalStore? _store;

  FriendRepository({required Dio dio}) : _dio = dio;

  /// 登录后注入本地存储
  void setStore(LocalStore store) => _store = store;

  /// 获取当前本地存储（供 Cubit 监听变更）
  LocalStore? get store => _store;

  Future<List<SearchUser>> searchUsers(String keyword, {int limit = 20}) async {
    final res = await _dio.get('/api/users/search', queryParameters: {
      'keyword': keyword,
      'limit': limit,
    });
    final List data = res.data['data'] as List;
    return data.map((e) => SearchUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sendRequest(String toUserId, {String? message}) async {
    await _dio.post('/api/friends/requests', data: {
      'to_user_id': int.parse(toUserId),
      if (message != null) 'message': message,
    });
  }

  Future<List<FriendRequest>> getReceivedRequests({int limit = 20, int offset = 0}) async {
    final res = await _dio.get('/api/friends/requests/received', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    final List data = res.data['data'] as List;
    return data.map((e) => FriendRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FriendRequest>> getSentRequests({int limit = 20, int offset = 0}) async {
    final res = await _dio.get('/api/friends/requests/sent', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    final List data = res.data['data'] as List;
    return data.map((e) => FriendRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> acceptRequest(String requestId) async {
    await _dio.post('/api/friends/requests/$requestId/accept');
  }

  Future<void> rejectRequest(String requestId) async {
    await _dio.post('/api/friends/requests/$requestId/reject');
  }

  Future<List<Friend>> getFriends({int limit = 1000, int offset = 0}) async {
    if (_store != null) {
      final cached = await _store!.getFriends();
      if (cached.isNotEmpty) return cached.map(_fromCached).toList();
      // 本地为空，fallback HTTP
    }
    final res = await _dio.get('/api/friends', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    final List data = res.data['data'] as List;
    return data.map((e) => Friend.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteFriend(String friendId) async {
    await _dio.delete('/api/friends/$friendId');
  }

  Future<void> deleteRequest(String requestId) async {
    await _dio.delete('/api/friends/requests/$requestId');
  }

  /// 获取用户公开资料
  Future<UserProfile> getUserProfile(String userId) async {
    final res = await _dio.get('/api/users/$userId');
    return UserProfile.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// CachedFriend → Friend
  Friend _fromCached(CachedFriend c) {
    return Friend(
      friendId: c.friendId,
      nickname: c.nickname,
      avatar: c.avatar,
      bio: c.bio,
      createdAt: DateTime.fromMillisecondsSinceEpoch(c.createdAt),
    );
  }
}
