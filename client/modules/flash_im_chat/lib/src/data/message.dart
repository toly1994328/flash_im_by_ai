enum MessageStatus { sending, sent, failed }

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final int seq;
  final String content;
  final MessageStatus status;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.seq,
    required this.content,
    this.status = MessageStatus.sent,
    required this.createdAt,
  });

  /// 从 HTTP JSON 解析
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'].toString(),
      senderName: json['sender_name'] as String? ?? '',
      senderAvatar: json['sender_avatar'] as String?,
      seq: json['seq'] as int,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 创建发送中的本地消息
  factory Message.sending({
    required String localId,
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String content,
  }) {
    return Message(
      id: localId,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      seq: 0,
      content: content,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );
  }

  Message copyWith({
    String? id,
    int? seq,
    MessageStatus? status,
    String? content,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      seq: seq ?? this.seq,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
