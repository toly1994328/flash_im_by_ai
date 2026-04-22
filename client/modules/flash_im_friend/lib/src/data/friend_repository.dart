import 'package:dio/dio.dart';
import 'friend.dart';

class FriendRepository {
  final Dio _dio;

  FriendRepository({required Dio dio}) : _dio = dio;

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
}
