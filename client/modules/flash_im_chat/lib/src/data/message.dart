import 'dart:convert';

enum MessageStatus { sending, sent, failed }

enum MessageType {
  text(0),
  image(1),
  video(2),
  file(3),
  audio(4),
  forward(5);

  final int value;
  const MessageType(this.value);

  static MessageType fromInt(int v) => switch (v) {
    1 => image,
    2 => video,
    3 => file,
    4 => audio,
    5 => forward,
    _ => text,
  };
}

class VideoExtra {
  final String thumbnailUrl;
  final int durationMs;
  final int width;
  final int height;
  final int fileSize;

  const VideoExtra({
    required this.thumbnailUrl,
    required this.durationMs,
    required this.width,
    required this.height,
    required this.fileSize,
  });

  factory VideoExtra.fromJson(Map<String, dynamic> json) => VideoExtra(
    thumbnailUrl: json['thumbnail_url'] as String? ?? '',
    durationMs: json['duration_ms'] as int? ?? 0,
    width: json['width'] as int? ?? 0,
    height: json['height'] as int? ?? 0,
    fileSize: json['file_size'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'thumbnail_url': thumbnailUrl,
    'duration_ms': durationMs,
    'width': width,
    'height': height,
    'file_size': fileSize,
  };

  String get formattedDuration {
    final seconds = durationMs ~/ 1000;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class FileExtra {
  final String fileName;
  final int fileSize;
  final String fileUrl;
  final String fileType;

  const FileExtra({
    required this.fileName,
    required this.fileSize,
    required this.fileUrl,
    required this.fileType,
  });

  factory FileExtra.fromJson(Map<String, dynamic> json) => FileExtra(
    fileName: json['file_name'] as String? ?? '',
    fileSize: json['file_size'] as int? ?? 0,
    fileUrl: json['file_url'] as String? ?? '',
    fileType: json['file_type'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'file_name': fileName,
    'file_size': fileSize,
    'file_url': fileUrl,
    'file_type': fileType,
  };

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

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
  final MessageType type;
  final Map<String, dynamic>? extra;

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
    this.type = MessageType.text,
    this.extra,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final rawType = json['msg_type'] as int? ?? 0;
    final parsedType = MessageType.fromInt(rawType);

    Map<String, dynamic>? extra;
    final rawExtra = json['extra'];
    if (rawExtra is Map<String, dynamic>) {
      extra = rawExtra;
    } else if (rawExtra is String && rawExtra.isNotEmpty) {
      try { extra = jsonDecode(rawExtra) as Map<String, dynamic>?; } catch (_) {}
    }

    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'].toString(),
      senderName: json['sender_name'] as String? ?? '',
      senderAvatar: json['sender_avatar'] as String?,
      seq: json['seq'] as int,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      type: parsedType,
      extra: extra,
    );
  }

  factory Message.sending({
    required String localId,
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? extra,
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
      type: type,
      extra: extra,
    );
  }

  Message copyWith({
    String? id,
    int? seq,
    MessageStatus? status,
    String? content,
    MessageType? type,
    Map<String, dynamic>? extra,
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
      type: type ?? this.type,
      extra: extra ?? this.extra,
    );
  }

  bool get isText => type == MessageType.text;
  bool get isImage => type == MessageType.image;
  bool get isVideo => type == MessageType.video;
  bool get isFile => type == MessageType.file;
  bool get isAudio => type == MessageType.audio;
  bool get isForward => type == MessageType.forward;

  /// 是否系统消息（sender_id=0）
  bool get isSystem => senderId == '0';

  /// 是否已撤回（status=1）
  bool get isRecalled => extra?['_recalled'] == true;

  VideoExtra? get videoExtra {
    if (extra == null || !isVideo) return null;
    try { return VideoExtra.fromJson(extra!); } catch (_) { return null; }
  }

  FileExtra? get fileExtra {
    if (extra == null || !isFile) return null;
    try { return FileExtra.fromJson(extra!); } catch (_) { return null; }
  }

  /// 生成会话列表预览文本
  String preview({bool isSelf = false}) {
    if (isRecalled) {
      return isSelf ? '你撤回了一条消息' : '$senderName撤回了一条消息';
    }
    return switch (type) {
      MessageType.image => '[图片]',
      MessageType.video => '[视频]',
      MessageType.file => '[文件]',
      MessageType.audio => '[语音]',
      _ => content,
    };
  }
}

/// 置顶消息
class PinnedMessage {
  final String pinId;
  final String messageId;
  final String content;
  final int msgType;
  final String senderName;
  final int pinnedBy;
  final DateTime pinnedAt;

  const PinnedMessage({
    required this.pinId,
    required this.messageId,
    required this.content,
    required this.msgType,
    required this.senderName,
    required this.pinnedBy,
    required this.pinnedAt,
  });

  factory PinnedMessage.fromJson(Map<String, dynamic> json) => PinnedMessage(
    pinId: json['pin_id'] as String,
    messageId: json['message_id'] as String,
    content: json['content'] as String? ?? '',
    msgType: json['msg_type'] as int? ?? 0,
    senderName: json['sender_name'] as String? ?? '',
    pinnedBy: json['pinned_by'] as int? ?? 0,
    pinnedAt: DateTime.parse(json['pinned_at'] as String),
  );
}
