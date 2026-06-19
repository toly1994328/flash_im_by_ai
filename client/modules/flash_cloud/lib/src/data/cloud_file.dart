/// 云空间文件列表项
class CloudFile {
  final int id;
  final String url;
  final String? thumbUrl;
  final int size;
  final String mimeType;
  final String mimeCategory;
  final int? width;
  final int? height;
  final int? durationMs;
  final String? originalName;
  final int refCount;
  final DateTime createdAt;

  const CloudFile({
    required this.id,
    required this.url,
    this.thumbUrl,
    required this.size,
    required this.mimeType,
    required this.mimeCategory,
    this.width,
    this.height,
    this.durationMs,
    this.originalName,
    required this.refCount,
    required this.createdAt,
  });

  factory CloudFile.fromJson(Map<String, dynamic> json) {
    return CloudFile(
      id: json['id'] as int,
      url: json['url'] as String,
      thumbUrl: json['thumb_url'] as String?,
      size: json['size'] as int,
      mimeType: json['mime_type'] as String,
      mimeCategory: json['mime_category'] as String,
      width: json['width'] as int?,
      height: json['height'] as int?,
      durationMs: json['duration_ms'] as int?,
      originalName: json['original_name'] as String?,
      refCount: json['ref_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get durationFormatted {
    if (durationMs == null) return '';
    final int seconds = durationMs! ~/ 1000;
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}

/// 文件详情（含引用会话）
class CloudFileDetail {
  final CloudFile file;
  final List<FileConversationRef> conversations;

  const CloudFileDetail({required this.file, required this.conversations});

  factory CloudFileDetail.fromJson(Map<String, dynamic> json) {
    final List<dynamic> convList = json['conversations'] as List<dynamic>? ?? [];
    return CloudFileDetail(
      file: CloudFile.fromJson(json['file'] as Map<String, dynamic>),
      conversations: convList.map((e) => FileConversationRef.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// 引用会话
class FileConversationRef {
  final String conversationId;
  final String conversationName;
  final int conversationType;
  final String? avatar;
  final int messageCount;

  const FileConversationRef({
    required this.conversationId,
    required this.conversationName,
    required this.conversationType,
    this.avatar,
    required this.messageCount,
  });

  factory FileConversationRef.fromJson(Map<String, dynamic> json) {
    return FileConversationRef(
      conversationId: json['conversation_id'] as String,
      conversationName: json['conversation_name'] as String? ?? '',
      conversationType: json['conversation_type'] as int? ?? 0,
      avatar: json['avatar'] as String?,
      messageCount: json['message_count'] as int? ?? 0,
    );
  }
}
