/// 群成员
class GroupMember {
  final String userId;
  final String nickname;
  final String? avatar;

  const GroupMember({required this.userId, required this.nickname, this.avatar});

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: (json['user_id'] ?? json['id']).toString(),
      nickname: json['nickname'] as String? ?? '?',
      avatar: json['avatar'] as String?,
    );
  }
}

/// 群详情
class GroupDetail {
  final String name;
  final int groupNo;
  final String? avatar;
  final String? announcement;
  final String ownerId;
  final bool joinVerification;
  final int status;
  final List<GroupMember> members;

  const GroupDetail({
    required this.name,
    required this.groupNo,
    this.avatar,
    this.announcement,
    required this.ownerId,
    this.joinVerification = false,
    this.status = 0,
    this.members = const [],
  });

  bool get isDisband => status == 1;

  factory GroupDetail.fromJson(Map<String, dynamic> json) {
    final List rawMembers = json['members'] as List? ?? [];
    return GroupDetail(
      name: json['name'] as String? ?? '未命名群聊',
      groupNo: json['group_no'] as int? ?? 0,
      avatar: json['avatar'] as String?,
      announcement: json['announcement'] as String?,
      ownerId: (json['owner_id'] ?? '').toString(),
      joinVerification: json['join_verification'] as bool? ?? false,
      status: json['status'] as int? ?? 0,
      members: rawMembers.map((m) => GroupMember.fromJson(m as Map<String, dynamic>)).toList(),
    );
  }
}
