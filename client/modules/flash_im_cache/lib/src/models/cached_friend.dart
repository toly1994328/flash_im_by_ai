/// 缓存好友（纯 Dart 模型，不依赖任何 ORM）
class CachedFriend {
  final String friendId;
  final String nickname;
  final String? avatar;
  final String? bio;
  final int createdAt; // 毫秒时间戳

  const CachedFriend({
    required this.friendId,
    required this.nickname,
    this.avatar,
    this.bio,
    required this.createdAt,
  });
}
