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
  final String letter; // 拼音首字母（A-Z / #），由调用方传入

  const SelectableMember({
    required this.id,
    required this.nickname,
    this.avatar,
    this.letter = '#',
  });
}

// ─── v0.0.2：搜索加群与入群审批 ───

/// 群搜索结果
class GroupSearchResult {
  final String id;
  final String? name;
  final String? avatar;
  final int? ownerId;
  final int groupNo;
  final int memberCount;
  final bool isMember;
  final bool joinVerification;
  final bool hasPendingRequest;

  const GroupSearchResult({
    required this.id,
    this.name,
    this.avatar,
    this.ownerId,
    required this.groupNo,
    required this.memberCount,
    required this.isMember,
    required this.joinVerification,
    required this.hasPendingRequest,
  });

  factory GroupSearchResult.fromJson(Map<String, dynamic> json) {
    return GroupSearchResult(
      id: json['id'] as String,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      ownerId: json['owner_id'] as int?,
      groupNo: json['group_no'] as int,
      memberCount: json['member_count'] as int,
      isMember: json['is_member'] as bool,
      joinVerification: json['join_verification'] as bool,
      hasPendingRequest: json['has_pending_request'] as bool,
    );
  }
}

/// 入群申请列表项（群主视角）
class JoinRequestItem {
  final String id;
  final String conversationId;
  final String? groupName;
  final String? groupAvatar;
  final int userId;
  final String nickname;
  final String? avatar;
  final String? message;
  final int status; // 0=待处理 1=已同意 2=已拒绝
  final DateTime createdAt;

  const JoinRequestItem({
    required this.id,
    required this.conversationId,
    this.groupName,
    this.groupAvatar,
    required this.userId,
    required this.nickname,
    this.avatar,
    this.message,
    required this.status,
    required this.createdAt,
  });

  factory JoinRequestItem.fromJson(Map<String, dynamic> json) {
    return JoinRequestItem(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      groupName: json['group_name'] as String?,
      groupAvatar: json['group_avatar'] as String?,
      userId: json['user_id'] as int,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String?,
      message: json['message'] as String?,
      status: json['status'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
