import 'package:dio/dio.dart';

class BlockedUser {
  final String userId;
  final String nickname;
  final String? avatar;
  final String blockedAt;

  const BlockedUser({
    required this.userId,
    required this.nickname,
    this.avatar,
    required this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
        userId: json['user_id'] as String,
        nickname: json['nickname'] as String,
        avatar: json['avatar'] as String?,
        blockedAt: json['blocked_at'] as String,
      );
}

class BlockRepository {
  final Dio _dio;

  BlockRepository({required Dio dio}) : _dio = dio;

  Future<void> report({
    required int targetType,
    required String targetId,
    required int reason,
    String? description,
  }) async {
    await _dio.post('/api/reports', data: {
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
      'description': ?description,
    });
  }

  Future<void> blockUser(int blockedId) async {
    await _dio.post('/api/blocks', data: {'blocked_id': blockedId});
  }

  Future<void> unblockUser(int blockedId) async {
    await _dio.delete('/api/blocks/$blockedId');
  }

  Future<List<BlockedUser>> getBlockList() async {
    final Response<dynamic> res = await _dio.get('/api/blocks');
    final List<dynamic> data =
        (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((dynamic e) => BlockedUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isBlocked(int userId) async {
    final Response<dynamic> res =
        await _dio.get('/api/blocks/check', queryParameters: {'user_id': userId});
    return (res.data as Map<String, dynamic>)['is_blocked'] as bool;
  }
}
