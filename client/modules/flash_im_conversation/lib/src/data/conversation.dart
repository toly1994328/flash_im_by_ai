/// 会话数据模型
class Conversation {
  final String id;
  final int type; // 0:单聊 1:群聊
  final String? name;
  final String? avatar;
  final String? peerUserId;
  final String? peerNickname;
  final String? peerAvatar;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final DateTime createdAt;
  final bool isSkeleton;

  const Conversation({
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
    this.isSkeleton = false,
  });

  /// 骨架会话：用 ConversationUpdate 帧的有限数据创建，等待 HTTP 补全
  factory Conversation.skeleton({
    required String id,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int unreadCount = 0,
  }) {
    return Conversation(
      id: id,
      type: 0,
      lastMessagePreview: lastMessagePreview,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
      createdAt: lastMessageAt ?? DateTime.now(),
      isSkeleton: true,
    );
  }

  /// 显示名称：单聊用对方昵称，群聊用群名
  String get displayName =>
      (type == 0 ? peerNickname : name) ?? '未知会话';

  /// 显示头像 URL
  String? get displayAvatar =>
      type == 0 ? peerAvatar : avatar;

  Conversation copyWith({
    int? unreadCount,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
  }) {
    return Conversation(
      id: id,
      type: type,
      name: name,
      avatar: avatar,
      peerUserId: peerUserId,
      peerNickname: peerNickname,
      peerAvatar: peerAvatar,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned,
      isMuted: isMuted,
      createdAt: createdAt,
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      type: json['conv_type'] as int,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      peerUserId: json['peer_user_id'] as String?,
      peerNickname: json['peer_nickname'] as String?,
      peerAvatar: json['peer_avatar'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessagePreview: json['last_message_preview'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
