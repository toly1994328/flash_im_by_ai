/// 用户信息（本地缓存 + 接口共用）
class User {
  final int userId;
  final String phone;
  final String nickname;
  final String avatar;

  const User({
    required this.userId,
    required this.phone,
    required this.nickname,
    required this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as int,
      phone: json['phone'] as String,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'phone': phone,
    'nickname': nickname,
    'avatar': avatar,
  };
}
