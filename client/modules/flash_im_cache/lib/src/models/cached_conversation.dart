/// 缓存会话（纯 Dart 模型，不依赖任何 ORM）
class CachedConversation {
  final String id;
  final int type; // 0 单聊 1 群聊
  final String? name;
  final String? avatar;
  final String? peerUserId;
  final String? peerNickname;
  final String? peerAvatar;
  final int? lastMessageAt; // 毫秒时间戳
  final String? lastMessagePreview;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final int createdAt;

  const CachedConversation({
    required this.id,
    required this.type,
    this.name,
    this.avatar,
    this.peerUserId,
    this.peerNickname,
    this.peerAvatar,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    required this.createdAt,
  });
}
