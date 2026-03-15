/// 用户信息
class UserProfile {
  final int userId;
  final String phone;
  final String nickname;
  final String avatar;

  const UserProfile({
    required this.userId,
    required this.phone,
    required this.nickname,
    required this.avatar,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as int,
      phone: json['phone'] as String,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String,
    );
  }
}
