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
