/// 登录接口返回
class LoginResult {
  final String token;
  final int userId;
  final bool hasPassword;

  const LoginResult({
    required this.token,
    required this.userId,
    required this.hasPassword,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token'] as String,
      userId: json['user_id'] as int,
      hasPassword: json['has_password'] as bool,
    );
  }
}

/// 用户信息（profile 接口返回）
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
}
