import 'package:dio/dio.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';
import 'group_models.dart';

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

  // ─── v0.0.2：搜索加群与入群审批 ───

  /// 搜索群聊
  Future<List<GroupSearchResult>> searchGroups(String keyword) async {
    final res = await _dio.get('/groups/search', queryParameters: {'keyword': keyword});
    return (res.data as List).map((e) => GroupSearchResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 申请入群，返回是否直接加入
  Future<bool> joinGroup(String groupId, {String? message}) async {
    final res = await _dio.post('/groups/$groupId/join', data: {
      if (message != null) 'message': message,
    });
    return (res.data as Map<String, dynamic>)['auto_approved'] as bool;
  }

  /// 群主审批入群申请
  Future<void> handleJoinRequest(String groupId, String requestId, {required bool approved}) async {
    await _dio.post('/groups/$groupId/join-requests/$requestId/handle', data: {
      'approved': approved,
    });
  }

  /// 查询入群申请列表（群主视角）
  Future<List<JoinRequestItem>> getJoinRequests() async {
    final res = await _dio.get('/groups/join-requests');
    return (res.data as List).map((e) => JoinRequestItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取群详情（群信息+成员列表）
  Future<Map<String, dynamic>> getGroupDetail(String groupId) async {
    final res = await _dio.get('/groups/$groupId/detail');
    return res.data as Map<String, dynamic>;
  }

  /// 群主修改群设置
  Future<void> updateGroupSettings(String groupId, {required bool joinVerification}) async {
    await _dio.put('/groups/$groupId/settings', data: {
      'join_verification': joinVerification,
    });
  }
}
