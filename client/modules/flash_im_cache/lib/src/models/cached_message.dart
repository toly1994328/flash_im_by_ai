/// 缓存消息（纯 Dart 模型，不依赖任何 ORM）
class CachedMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final int seq;
  final int msgType;
  final String content;
  final String? extra;
  final int status;
  final int createdAt; // 毫秒时间戳

  const CachedMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.seq,
    required this.msgType,
    required this.content,
    this.extra,
    this.status = 0,
    required this.createdAt,
  });
}
