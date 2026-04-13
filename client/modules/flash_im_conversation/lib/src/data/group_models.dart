/// 群搜索结果
class GroupSearchResult {
  final String id;
  final String? name;
  final String? avatar;
  final int memberCount;
  final bool isMember;
  final bool joinVerification;

  const GroupSearchResult({
    required this.id,
    this.name,
    this.avatar,
    required this.memberCount,
    required this.isMember,
    required this.joinVerification,
  });

  factory GroupSearchResult.fromJson(Map<String, dynamic> json) {
    return GroupSearchResult(
      id: json['id'] as String,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
      isMember: json['is_member'] as bool? ?? false,
      joinVerification: json['join_verification'] as bool? ?? false,
    );
  }
}

/// 申请入群响应
class JoinGroupResponse {
  final bool autoApproved;
  final String? ownerId;
  final String? groupName;

  const JoinGroupResponse({
    required this.autoApproved,
    this.ownerId,
    this.groupName,
  });

  factory JoinGroupResponse.fromJson(Map<String, dynamic> json) {
    return JoinGroupResponse(
      autoApproved: json['auto_approved'] as bool? ?? false,
      ownerId: json['owner_id'] as String?,
      groupName: json['group_name'] as String?,
    );
  }
}

/// 我的群通知项（群主视角的待处理入群申请）
class MyGroupNotification {
  final String id;
  final int userId;
  final String conversationId;
  final String? message;
  final int status;
  final String nickname;
  final String? avatar;
  final String? groupName;
  final DateTime createdAt;

  const MyGroupNotification({
    required this.id,
    required this.userId,
    required this.conversationId,
    this.message,
    required this.status,
    required this.nickname,
    this.avatar,
    this.groupName,
    required this.createdAt,
  });

  factory MyGroupNotification.fromJson(Map<String, dynamic> json) {
    return MyGroupNotification(
      id: json['id'] as String,
      userId: json['user_id'] as int,
      conversationId: json['conversation_id'] as String,
      message: json['message'] as String?,
      status: json['status'] as int? ?? 0,
      nickname: json['nickname'] as String? ?? '未知用户',
      avatar: json['avatar'] as String?,
      groupName: json['group_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// CreateGroupPage 返回值
class CreateGroupResult {
  final String name;
  final List<int> memberIds;

  const CreateGroupResult({required this.name, required this.memberIds});
}

/// 可选成员（CreateGroupPage 用，避免依赖 flash_im_friend）
class SelectableMember {
  final String id;
  final String nickname;
  final String? avatar;

  const SelectableMember({
    required this.id,
    required this.nickname,
    this.avatar,
  });
}
