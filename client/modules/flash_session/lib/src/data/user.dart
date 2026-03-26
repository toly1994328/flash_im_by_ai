/// 用户信息（本地缓存 + 接口共用）
class User {
  final int userId;
  final String phone;
  final String nickname;
  final String avatar;
  final String signature;

  const User({
    required this.userId,
    required this.phone,
    required this.nickname,
    required this.avatar,
    this.signature = '',
  });

  /// 是否为自定义头像（非 identicon 默认头像）
  bool get hasCustomAvatar => !avatar.startsWith('identicon:');

  /// 提取 identicon seed（仅默认头像时有意义）
  String get identiconSeed =>
      avatar.startsWith('identicon:') ? avatar.substring('identicon:'.length) : '';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as int,
      phone: json['phone'] as String,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String,
      signature: json['signature'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'phone': phone,
    'nickname': nickname,
    'avatar': avatar,
    'signature': signature,
  };
}
