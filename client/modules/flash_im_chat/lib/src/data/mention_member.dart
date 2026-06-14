/// 群成员信息（@选择用）
class MentionMember {
  final String userId;
  final String nickname;
  final String? avatar;

  const MentionMember({required this.userId, required this.nickname, this.avatar});
}
