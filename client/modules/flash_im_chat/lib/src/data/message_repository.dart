import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flash_im_cache/flash_im_cache.dart';
import 'package:fx_logger/fx_logger.dart';
import 'i_message_repository.dart';
import 'message.dart';
import 'message_ext.dart';

class ImageUploadResult {
  final int fileId;
  final String originalUrl;
  final String thumbnailUrl;
  final int width;
  final int height;
  final int size;
  final String format;
  final bool isDedup;

  const ImageUploadResult({
    required this.fileId,
    required this.originalUrl,
    required this.thumbnailUrl,
    required this.width,
    required this.height,
    required this.size,
    required this.format,
    required this.isDedup,
  });

  factory ImageUploadResult.fromJson(Map<String, dynamic> json) =>
      ImageUploadResult(
        fileId: json['file_id'] as int? ?? 0,
        originalUrl: json['original_url'] as String,
        thumbnailUrl: json['thumbnail_url'] as String? ?? '',
        width: json['width'] as int? ?? 0,
        height: json['height'] as int? ?? 0,
        size: json['size'] as int? ?? 0,
        format: json['format'] as String? ?? '',
        isDedup: json['is_dedup'] as bool? ?? false,
      );
}

class VideoUploadResult {
  final int fileId;
  final String videoUrl;
  final String thumbnailUrl;
  final int durationMs;
  final int width;
  final int height;
  final int fileSize;
  final bool isDedup;

  const VideoUploadResult({
    required this.fileId,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.durationMs,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.isDedup,
  });

  factory VideoUploadResult.fromJson(Map<String, dynamic> json) =>
      VideoUploadResult(
        fileId: json['file_id'] as int? ?? 0,
        videoUrl: json['video_url'] as String,
        thumbnailUrl: json['thumbnail_url'] as String? ?? '',
        durationMs: json['duration_ms'] as int? ?? 0,
        width: json['width'] as int? ?? 0,
        height: json['height'] as int? ?? 0,
        fileSize: json['file_size'] as int? ?? 0,
        isDedup: json['is_dedup'] as bool? ?? false,
      );
}

class FileUploadResult {
  final int fileId;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String fileType;
  final bool isDedup;

  const FileUploadResult({
    required this.fileId,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.isDedup,
  });

  factory FileUploadResult.fromJson(Map<String, dynamic> json) =>
      FileUploadResult(
        fileId: json['file_id'] as int? ?? 0,
        fileUrl: json['file_url'] as String,
        fileName: json['file_name'] as String? ?? '',
        fileSize: json['file_size'] as int? ?? 0,
        fileType: json['file_type'] as String? ?? '',
        isDedup: json['is_dedup'] as bool? ?? false,
      );
}

class MessageRepository implements IMessageRepository {
  final Dio _dio;
  LocalStore? _store;
  static final _log = FxLog('MsgRepo');

  MessageRepository({required Dio dio}) : _dio = dio;

  /// 暴露 Dio 实例（会话选择器等需要直接调用其他接口）
  Dio get dio => _dio;

  /// 登录后注入本地存储
  void setStore(LocalStore store) => _store = store;

  /// 秒传检查（带配额预检）
  @override
  Future<Map<String, dynamic>?> checkHash(String hash, {int? size}) async {
    try {
      final Map<String, dynamic> params = {'hash': hash};
      if (size != null) params['size'] = size;
      final Response<dynamic> res = await _dio.get('/api/storage/check', queryParameters: params);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow; // 403 QUOTA_EXCEEDED 等错误继续抛出
    }
  }

  /// 获取当前本地存储
  @override
  LocalStore? get store => _store;

  /// 消息撤回
  @override
  Future<void> recallMessage(String conversationId, String messageId) async {
    await _dio.post('/conversations/$conversationId/messages/$messageId/recall');
  }

  @override
  Future<List<Message>> getMessages(
    String conversationId, {
    int? beforeSeq,
    int limit = 50,
  }) async {
    _log.d('getMessages convId=$conversationId, beforeSeq=$beforeSeq, limit=$limit, hasStore=${_store != null}');
    if (_store != null) {
      final cached = await _store!.getMessages(conversationId,
          beforeSeq: beforeSeq, limit: limit);
      _log.d('local cached: ${cached.length} messages');
      if (cached.isNotEmpty) {
        final trashIds = await _store!.getTrashIds(entityType: 'message');
        final trashSet = trashIds.toSet();
        final filtered = cached.where((m) => !trashSet.contains(m.id)).toList();
        _log.d('after trash filter: ${filtered.length} messages');
        if (filtered.isNotEmpty) {
          _log.d('using local data');
          return filtered.map(_fromCached).toList();
        }
      }
      // 本地数据不足或为空，fallback HTTP
    }
    _log.d('fetching from HTTP...');
    final params = <String, dynamic>{'limit': limit};
    if (beforeSeq != null) params['before_seq'] = beforeSeq;
    final res = await _dio.get(
      '/conversations/$conversationId/messages',
      queryParameters: params,
    );
    final List data = res.data as List;
    _log.d('HTTP returned: ${data.length} messages');
    final messages = data.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();

    // HTTP 拉到的消息写入本地缓存
    if (_store != null && messages.isNotEmpty) {
      final cached = messages.map((m) => m.toCached()).toList();
      _store!.cacheMessages(cached, conversationId: conversationId);
      _log.d('cached ${cached.length} messages to local');
    }

    return messages;
  }

  @override
  Future<ImageUploadResult> uploadImage(
    String filePath, {
    required String hash,
    void Function(double progress)? onProgress,
  }) async {
    final String fileName = filePath.split('/').last.split('\\').last;
    final FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'hash': hash,
    });
    final Response<dynamic> res = await _dio.post(
      '/api/upload/image',
      data: formData,
      onSendProgress: (count, total) {
        if (total > 0) onProgress?.call(count / total);
      },
    );
    return ImageUploadResult.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<VideoUploadResult> uploadVideo(
    String videoPath,
    String thumbnailPath,
    int durationMs, {
    required String hash,
    int width = 0,
    int height = 0,
    void Function(double progress)? onProgress,
  }) async {
    final FormData formData = FormData.fromMap({
      'video': await MultipartFile.fromFile(videoPath),
      'thumbnail': await MultipartFile.fromFile(thumbnailPath),
      'hash': hash,
      'duration_ms': durationMs.toString(),
      'width': width.toString(),
      'height': height.toString(),
    });
    final Response<dynamic> res = await _dio.post(
      '/api/upload/video',
      data: formData,
      onSendProgress: (count, total) {
        if (total > 0) onProgress?.call(count / total);
      },
    );
    return VideoUploadResult.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<FileUploadResult> uploadFile(
    String filePath, {
    required String hash,
    void Function(double progress)? onProgress,
  }) async {
    final String fileName = filePath.split('/').last.split('\\').last;
    final FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'hash': hash,
    });
    final Response<dynamic> res = await _dio.post(
      '/api/upload/file',
      data: formData,
      onSendProgress: (count, total) {
        if (total > 0) onProgress?.call(count / total);
      },
    );
    return FileUploadResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// 获取会话已读位置
  @override
  Future<Map<String, int>> getReadSeq(String conversationId) async {
    final res = await _dio.get('/conversations/$conversationId/read-seq');
    final Map<String, dynamic> data =
        res.data['members_read_seq'] as Map<String, dynamic>? ?? {};
    return data.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  /// 获取消息已读/未读成员列表
  Future<Map<String, dynamic>> getReadStatus(
    String conversationId,
    String messageId,
  ) async {
    final res = await _dio.get(
      '/conversations/$conversationId/messages/$messageId/read-status',
    );
    return res.data as Map<String, dynamic>;
  }

  /// 下载文件到本地目录
  /// 返回本地文件路径
  @override
  Future<String> downloadFile(
    String url,
    String savePath, {
    void Function(double progress)? onProgress,
  }) async {
    await _dio.download(
      url,
      savePath,
      onReceiveProgress: (count, total) {
        if (total > 0) onProgress?.call(count / total);
      },
    );
    return savePath;
  }

  /// CachedMessage → Message
  Message _fromCached(CachedMessage c) {
    final parsedType = MessageType.fromInt(c.msgType);
    Map<String, dynamic>? extra;
    if (c.extra != null && c.extra!.isNotEmpty) {
      try {
        extra = jsonDecode(c.extra!) as Map<String, dynamic>?;
      } catch (_) {}
    }
    return Message(
      id: c.id,
      conversationId: c.conversationId,
      senderId: c.senderId,
      senderName: c.senderName,
      senderAvatar: c.senderAvatar,
      seq: c.seq,
      content: c.content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(c.createdAt),
      type: parsedType,
      extra: extra,
      localData: c.localData,
    );
  }

  // ─── 转发 ───

  /// 转发消息（单条/合并）
  @override
  Future<Map<String, dynamic>> forwardMessage({
    required String sourceConvId,
    required List<String> messageIds,
    required String targetConvId,
    required String forwardType,
  }) async {
    final res = await _dio.post('/conversations/$sourceConvId/messages/forward', data: {
      'message_ids': messageIds,
      'target_conversation_id': targetConvId,
      'forward_type': forwardType,
    });
    return res.data as Map<String, dynamic>;
  }

  // ─── 置顶 ───

  /// 置顶消息
  @override
  Future<Map<String, dynamic>> pinMessage(String convId, String messageId) async {
    final res = await _dio.post('/conversations/$convId/messages/pin', data: {
      'message_id': messageId,
    });
    return res.data as Map<String, dynamic>;
  }

  /// 取消置顶
  @override
  Future<void> unpinMessage(String convId, String pinId) async {
    await _dio.delete('/conversations/$convId/messages/pin/$pinId');
  }

  /// 查询置顶列表
  @override
  Future<List<Map<String, dynamic>>> getPinnedMessages(String convId) async {
    final res = await _dio.get('/conversations/$convId/messages/pinned');
    return (res.data as List).cast<Map<String, dynamic>>();
  }
}
