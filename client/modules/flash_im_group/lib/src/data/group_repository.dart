import 'package:dio/dio.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';

/// 群聊 API 调用
class GroupRepository {
  final Dio _dio;

  GroupRepository({required Dio dio}) : _dio = dio;

  /// 创建群聊
  Future<Conversation> createGroup({
    required String name,
    required List<int> memberIds,
  }) async {
    final res = await _dio.post('/groups', data: {
      'name': name,
      'member_ids': memberIds,
    });
    return Conversation.fromJson(res.data as Map<String, dynamic>);
  }
}
