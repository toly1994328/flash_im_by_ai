/// 好友搜索结果项
class FriendSearchItem {
  final String friendId;
  final String nickname;
  final String? avatar;

  const FriendSearchItem({
    required this.friendId,
    required this.nickname,
    this.avatar,
  });

  factory FriendSearchItem.fromJson(Map<String, dynamic> json) {
    return FriendSearchItem(
      friendId: json['friend_id'] as String,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String?,
    );
  }
}

/// 群聊搜索结果项
class GroupSearchItem {
  final String conversationId;
  final String? name;
  final String? avatar;
  final int memberCount;

  const GroupSearchItem({
    required this.conversationId,
    this.name,
    this.avatar,
    required this.memberCount,
  });

  factory GroupSearchItem.fromJson(Map<String, dynamic> json) {
    return GroupSearchItem(
      conversationId: json['conversation_id'] as String,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 消息搜索结果项
class MessageSearchItem {
  final String messageId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime createdAt;
  final int? seq;

  const MessageSearchItem({
    required this.messageId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.createdAt,
    this.seq,
  });

  factory MessageSearchItem.fromJson(Map<String, dynamic> json) {
    return MessageSearchItem(
      messageId: json['message_id'] as String,
      senderName: json['sender_name'] as String? ?? '',
      senderAvatar: json['sender_avatar'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      seq: (json['seq'] as num?)?.toInt(),
    );
  }
}

/// 消息搜索分组（按会话聚合）
class MessageSearchGroup {
  final String conversationId;
  final String conversationName;
  final String? conversationAvatar;
  final int convType;
  final int matchCount;
  final List<MessageSearchItem> messages;

  const MessageSearchGroup({
    required this.conversationId,
    required this.conversationName,
    this.conversationAvatar,
    required this.convType,
    required this.matchCount,
    required this.messages,
  });

  factory MessageSearchGroup.fromJson(Map<String, dynamic> json) {
    final msgList = (json['messages'] as List<dynamic>?)
            ?.map((e) =>
                MessageSearchItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return MessageSearchGroup(
      conversationId: json['conversation_id'] as String,
      conversationName: json['conversation_name'] as String? ?? '',
      conversationAvatar: json['conversation_avatar'] as String?,
      convType: (json['conv_type'] as num?)?.toInt() ?? 0,
      matchCount: (json['match_count'] as num?)?.toInt() ?? 0,
      messages: msgList,
    );
  }
}

/// 综合搜索结果
class SearchResult {
  final List<FriendSearchItem> friends;
  final List<GroupSearchItem> groups;
  final List<MessageSearchGroup> messageGroups;
  final String? friendError;
  final String? groupError;
  final String? messageError;

  const SearchResult({
    this.friends = const [],
    this.groups = const [],
    this.messageGroups = const [],
    this.friendError,
    this.groupError,
    this.messageError,
  });

  /// 三个接口是否全部成功
  bool get allSuccess =>
      friendError == null && groupError == null && messageError == null;

  /// 是否有任何搜索结果
  bool get hasAnyResult =>
      friends.isNotEmpty ||
      groups.isNotEmpty ||
      messageGroups.isNotEmpty;
}
