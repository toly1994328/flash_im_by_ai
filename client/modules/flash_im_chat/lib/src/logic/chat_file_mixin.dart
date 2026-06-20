import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fx_logger/fx_logger.dart';
import 'package:fx_media/fx_media.dart';
import 'package:flash_im_core/flash_im_core.dart' hide MessageStatus, MessageType;
import 'package:flash_im_core/flash_im_core.dart' as proto show MessageType;
import 'package:flash_shared/flash_shared.dart' show ShowToastEvent;

import '../data/file_hash.dart';
import '../data/i_message_repository.dart';
import '../data/message.dart';
import 'chat_state.dart';

/// 文件发送限制配置
class FileSendLimits {
  /// 图片大小上限（字节），默认 50MB
  final int maxImageSize;

  /// 视频大小上限（字节），默认 50MB
  final int maxVideoSize;

  /// 文件大小上限（字节），默认 50MB
  final int maxFileSize;

  /// 音频时长上限（毫秒），默认 2 分钟
  final int maxAudioDurationMs;

  const FileSendLimits({
    this.maxImageSize = 50 * 1024 * 1024,
    this.maxVideoSize = 50 * 1024 * 1024,
    this.maxFileSize = 50 * 1024 * 1024,
    this.maxAudioDurationMs = 2 * 60 * 1000,
  });

  static const FileSendLimits defaultLimits = FileSendLimits();
}

/// 文件类消息发送与下载的 Mixin。
///
/// 包含图片、视频、文件的发送以及文件下载逻辑。
mixin ChatFileMixin on Cubit<ChatState> {
  static final _log = FxLog('Chat');

  // ─── 抽象 getter / 方法，由 ChatCubit 实现 ───

  IMessageRepository get repository;
  WsClient get wsClient;
  String get conversationId;
  String get currentUserId;
  String get currentUserName;
  String? get currentUserAvatar;
  Map<String, String> get pendingMessages;
  FileSendLimits get fileSendLimits;
  int nextLocalId();
  void setupTimeout(String clientId, String localId, Duration timeout);
  void markFailed(String localId);

  /// 暂存发送中的本地文件路径：localId → localPath
  final Map<String, String> pendingLocalPaths = {};

  // ─── 公共预检方法 ───

  /// 上传前预检：算 hash → 秒传检查 + 配额预检
  ///
  /// 返回值：
  /// - (hash, dedupResult) 当 dedupResult != null 表示秒传命中
  /// - 配额不足时内部弹 toast 并抛出异常（调用方 catch 后 return）
  Future<(String hash, Map<String, dynamic>? dedup)> _preUploadCheck(String filePath, int fileSize) async {
    _log.d('[PreCheck] start: file=$filePath, size=$fileSize');
    final String hash = await computeFileSha1(filePath);
    _log.d('[PreCheck] hash=$hash, checking dedup...');
    final Map<String, dynamic>? existing = await repository.checkHash(hash, size: fileSize);
    _log.d('[PreCheck] dedup result: ${existing != null ? 'hit' : 'miss'}');
    return (hash, existing);
  }

  // ─── 图片发送 ───

  /// 从本地文件发送图片消息
  Future<void> sendImageFromFile(String filePath) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final int localFileSize = await File(filePath).length();

    // 大小限制校验
    if (localFileSize > fileSendLimits.maxImageSize) {
      _log.w('image too large: $localFileSize > ${fileSendLimits.maxImageSize}');
      ShowToastEvent('图片大小超过限制（${_formatSize(fileSendLimits.maxImageSize)}）').emit();
      return;
    }

    // 计算 hash + 秒传检查 + 配额预检（在创建占位消息之前）
    final String hash;
    final Map<String, dynamic>? dedup;
    try {
      (hash, dedup) = await _preUploadCheck(filePath, localFileSize);
    } on DioException catch (e) {
      if (_handleQuotaError(e)) return;
      rethrow;
    }

    if (dedup != null) {
      _log.d('image dedup hit: file_id=${dedup['file_id']}');
      _sendDedupImageMessage(current, filePath, dedup);
      return;
    }

    // 配额充足 + 非秒传，走正常上传流程
    final String localId = 'local_${nextLocalId()}';
    pendingLocalPaths[localId] = filePath;

    // 读取图片尺寸
    int imgWidth = 0;
    int imgHeight = 0;
    try {
      final Uint8List bytes = await File(filePath).readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      imgWidth = frame.image.width;
      imgHeight = frame.image.height;
      frame.image.dispose();
    } catch (_) {}

    final Message localMessage = Message.sending(
      localId: localId,
      conversationId: conversationId,
      senderId: currentUserId,
      senderName: currentUserName,
      senderAvatar: currentUserAvatar,
      content: filePath,
      type: MessageType.image,
      extra: {'size': localFileSize, 'width': imgWidth, 'height': imgHeight},
    );
    emit(current.copyWith(messages: [...current.messages, localMessage]));

    try {
      final result = await repository.uploadImage(filePath, hash: hash, onProgress: (p) {
        _log.d('image progress: ${(p * 100).toInt()}%');
        final s = state;
        if (s is ChatLoaded) emit(s.copyWith(uploadProgress: p));
      });

      final afterUpload = state;
      if (afterUpload is ChatLoaded) {
        emit(afterUpload.copyWith(clearUploadProgress: true));
      }

      final imageExtra = {
        'width': result.width,
        'height': result.height,
        'size': result.size,
        'format': result.format,
        'thumbnail_url': result.thumbnailUrl,
      };

      final latest = state;
      _log.d('[ImgSend] upload done: url=${result.originalUrl}, state=${latest.runtimeType}');
      if (latest is ChatLoaded) {
        final updated = latest.messages.map((m) {
          if (m.id == localId) {
            return m.copyWith(content: result.originalUrl, extra: imageExtra);
          }
          return m;
        }).toList();
        emit(latest.copyWith(messages: updated));
      }

      final clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
      pendingMessages[clientId] = localId;
      _log.d('[ImgSend] ws send: clientId=$clientId');
      wsClient.sendMessage(
        conversationId: conversationId,
        content: result.originalUrl,
        type: proto.MessageType.IMAGE,
        extra: utf8.encode(jsonEncode(imageExtra)),
        clientId: clientId,
      );

      setupTimeout(clientId, localId, const Duration(seconds: 10));
    } catch (e) {
      // Broken pipe / 网络断开时，如果进度已达 100% 可能后端已成功
      // 重试一次秒传检查（hash 已算过），如果命中说明上传其实成功了
      if (_isBrokenPipe(e)) {
        _log.w('[ImgSend] broken pipe, retrying dedup check...');
        try {
          final Map<String, dynamic>? retryDedup = await repository.checkHash(hash, size: localFileSize);
          if (retryDedup != null) {
            _log.d('[ImgSend] retry dedup hit, recovering...');
            final ChatState current2 = state;
            if (current2 is ChatLoaded) {
              _sendDedupImageMessage(current2, filePath, retryDedup);
            }
            return;
          }
        } catch (_) {}
      }
      _log.e('[ImgSend] failed', error: e);
      _handleQuotaError(e);
      markFailed(localId);
    }
  }

  // ─── 视频发送 ───

  /// 从本地文件发送视频消息
  Future<void> sendVideoFromFile(String filePath, String thumbnailPath, int durationMs, {int width = 0, int height = 0}) async {
    final current = state;
    if (current is! ChatLoaded) return;

    // 大小限制校验
    final int videoFileSize = await File(filePath).length();
    if (videoFileSize > fileSendLimits.maxVideoSize) {
      _log.w('video too large: $videoFileSize > ${fileSendLimits.maxVideoSize}');
      ShowToastEvent('视频大小超过限制（${_formatSize(fileSendLimits.maxVideoSize)}）').emit();
      return;
    }

    // 计算 hash + 秒传检查 + 配额预检（在创建占位消息之前）
    final String hash;
    final Map<String, dynamic>? dedup;
    try {
      (hash, dedup) = await _preUploadCheck(filePath, videoFileSize);
    } on DioException catch (e) {
      if (_handleQuotaError(e)) return;
      rethrow;
    }

    if (dedup != null) {
      _log.d('video dedup hit: file_id=${dedup['file_id']}');
      final String videoUrl = dedup['url'] as String;
      final String thumbUrl = dedup['thumb_url'] as String? ?? '';
      final int dur = dedup['duration_ms'] as int? ?? durationMs;
      final int w = dedup['width'] as int? ?? width;
      final int h = dedup['height'] as int? ?? height;
      final int sz = dedup['size'] as int? ?? 0;

      final String localId = 'local_${nextLocalId()}';
      pendingLocalPaths[localId] = filePath;
      final VideoExtra videoExtra = VideoExtra(thumbnailUrl: thumbUrl, durationMs: dur, width: w, height: h, fileSize: sz);
      final Message localMessage = Message.sending(
        localId: localId, conversationId: conversationId, senderId: currentUserId,
        senderName: currentUserName, senderAvatar: currentUserAvatar,
        content: videoUrl, type: MessageType.video, extra: videoExtra.toJson(),
      );
      emit(current.copyWith(messages: [...current.messages, localMessage]));
      final String clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
      pendingMessages[clientId] = localId;
      wsClient.sendMessage(conversationId: conversationId, content: videoUrl, type: proto.MessageType.VIDEO, extra: utf8.encode(jsonEncode(videoExtra.toJson())), clientId: clientId);
      setupTimeout(clientId, localId, const Duration(seconds: 30));
      return;
    }

    // 正常上传流程
    final String localId = 'local_${nextLocalId()}';
    pendingLocalPaths[localId] = filePath;
    final Message localMessage = Message.sending(
      localId: localId,
      conversationId: conversationId,
      senderId: currentUserId,
      senderName: currentUserName,
      senderAvatar: currentUserAvatar,
      content: thumbnailPath,
      type: MessageType.video,
      extra: {'width': width, 'height': height, 'duration_ms': durationMs},
    );
    emit(current.copyWith(messages: [...current.messages, localMessage]));

    try {
      final result = await repository.uploadVideo(
        filePath, thumbnailPath, durationMs,
        hash: hash, width: width, height: height,
        onProgress: (p) {
          _log.d('video progress: ${(p * 100).toInt()}%');
          final s = state;
          if (s is ChatLoaded) emit(s.copyWith(uploadProgress: p));
        },
      );

      final afterUpload = state;
      if (afterUpload is ChatLoaded) {
        emit(afterUpload.copyWith(clearUploadProgress: true));
      }

      final videoExtra = VideoExtra(
        thumbnailUrl: result.thumbnailUrl,
        durationMs: result.durationMs,
        width: result.width,
        height: result.height,
        fileSize: result.fileSize,
      );

      final latest = state;
      if (latest is ChatLoaded) {
        final String localDataJson = jsonEncode({
          'path': filePath,
          'thumbnail_path': thumbnailPath,
          'cached_at': DateTime.now().millisecondsSinceEpoch,
        });
        final updated = latest.messages.map((m) {
          if (m.id == localId) {
            return m.copyWith(content: result.videoUrl, extra: videoExtra.toJson(), localData: localDataJson);
          }
          return m;
        }).toList();
        emit(latest.copyWith(messages: updated));
      }

      final clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
      pendingMessages[clientId] = localId;
      wsClient.sendMessage(
        conversationId: conversationId,
        content: result.videoUrl,
        type: proto.MessageType.VIDEO,
        extra: utf8.encode(jsonEncode(videoExtra.toJson())),
        clientId: clientId,
      );

      setupTimeout(clientId, localId, const Duration(seconds: 30));
    } catch (e) {
      _handleQuotaError(e);
      markFailed(localId);
    }
  }

  // ─── 文件发送 ───

  /// 从文件选择器发送文件消息
  Future<void> sendFileFromPicker(String filePath) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final String fileName = filePath.split('/').last.split('\\').last;
    final int fileSize = await File(filePath).length();

    // 大小限制校验
    if (fileSize > fileSendLimits.maxFileSize) {
      _log.w('file too large: $fileSize > ${fileSendLimits.maxFileSize}');
      ShowToastEvent('文件大小超过限制（${_formatSize(fileSendLimits.maxFileSize)}）').emit();
      return;
    }

    // 预检：hash + 秒传 + 配额（在占位消息之前）
    final String hash;
    final Map<String, dynamic>? dedup;
    try {
      (hash, dedup) = await _preUploadCheck(filePath, fileSize);
    } on DioException catch (e) {
      if (_handleQuotaError(e)) return;
      rethrow;
    }

    if (dedup != null) {
      _log.d('file dedup hit: file_id=${dedup['file_id']}');
      final String fileUrl = dedup['url'] as String;
      final int sz = dedup['size'] as int? ?? 0;
      final String localId = 'local_${nextLocalId()}';
      pendingLocalPaths[localId] = filePath;
      final FileExtra fileExtra = FileExtra(fileName: fileName, fileSize: sz, fileUrl: fileUrl, fileType: fileName.split('.').last);
      final Message localMessage = Message.sending(
        localId: localId, conversationId: conversationId, senderId: currentUserId,
        senderName: currentUserName, senderAvatar: currentUserAvatar,
        content: fileUrl, type: MessageType.file, extra: fileExtra.toJson(),
      );
      emit(current.copyWith(messages: [...current.messages, localMessage]));
      final String clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
      pendingMessages[clientId] = localId;
      wsClient.sendMessage(conversationId: conversationId, content: fileUrl, type: proto.MessageType.FILE, extra: utf8.encode(jsonEncode(fileExtra.toJson())), clientId: clientId);
      setupTimeout(clientId, localId, const Duration(seconds: 30));
      return;
    }

    // 正常上传流程
    final String localId = 'local_${nextLocalId()}';
    pendingLocalPaths[localId] = filePath;
    _log.d('[FileSend] start: localId=$localId, file=$fileName, size=$fileSize');
    final Message localMessage = Message.sending(
      localId: localId, conversationId: conversationId, senderId: currentUserId,
      senderName: currentUserName, senderAvatar: currentUserAvatar,
      content: fileName, type: MessageType.file,
      extra: {'file_name': fileName, 'file_type': fileName.split('.').last, 'file_size': fileSize},
    );
    emit(current.copyWith(messages: [...current.messages, localMessage]));

    try {
      final result = await repository.uploadFile(filePath, hash: hash, onProgress: (p) {
        _log.d('[FileSend] progress: ${(p * 100).toInt()}%');
        final s = state;
        if (s is ChatLoaded) emit(s.copyWith(uploadProgress: p));
      });

      _log.d('[FileSend] upload done: url=${result.fileUrl}, name=${result.fileName}');

      final afterUpload = state;
      if (afterUpload is ChatLoaded) {
        emit(afterUpload.copyWith(clearUploadProgress: true));
      }

      final fileExtra = FileExtra(
        fileName: result.fileName,
        fileSize: result.fileSize,
        fileUrl: result.fileUrl,
        fileType: result.fileType,
      );

      final latest = state;
      if (latest is ChatLoaded) {
        final updated = latest.messages.map((m) {
          if (m.id == localId) {
            return m.copyWith(content: result.fileUrl, extra: fileExtra.toJson());
          }
          return m;
        }).toList();
        emit(latest.copyWith(messages: updated));
      }

      final clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
      pendingMessages[clientId] = localId;
      _log.d('[FileSend] ws send: clientId=$clientId, content=${result.fileUrl}');
      wsClient.sendMessage(
        conversationId: conversationId,
        content: result.fileUrl,
        type: proto.MessageType.FILE,
        extra: utf8.encode(jsonEncode(fileExtra.toJson())),
        clientId: clientId,
      );

      setupTimeout(clientId, localId, const Duration(seconds: 30));
    } catch (e) {
      _log.e('[FileSend] failed', error: e);
      _handleQuotaError(e);
      markFailed(localId);
    }
  }

  // ─── 语音发送 ───

  /// 从录音文件发送语音消息
  Future<void> sendAudioFromFile(String filePath, int durationMs) async {
    final current = state;
    if (current is! ChatLoaded) return;

    // 时长限制校验
    if (durationMs > fileSendLimits.maxAudioDurationMs) {
      _log.w('audio too long: ${durationMs}ms > ${fileSendLimits.maxAudioDurationMs}ms');
      ShowToastEvent('语音时长超过限制（${fileSendLimits.maxAudioDurationMs ~/ 60000}分钟）').emit();
      return;
    }

    final int fileSize = await File(filePath).length();

    // 预检：hash + 秒传 + 配额（在占位消息之前）
    final String hash;
    final Map<String, dynamic>? dedup;
    try {
      (hash, dedup) = await _preUploadCheck(filePath, fileSize);
    } on DioException catch (e) {
      if (_handleQuotaError(e)) return;
      rethrow;
    }

    if (dedup != null) {
      _log.d('audio dedup hit: file_id=${dedup['file_id']}');
      final String audioUrl = dedup['url'] as String;
      final int sz = dedup['size'] as int? ?? 0;
      final String localId = 'local_${nextLocalId()}';
      pendingLocalPaths[localId] = filePath;
      final Map<String, dynamic> extra = {'duration_ms': durationMs, 'file_size': sz};
      final Message localMessage = Message.sending(
        localId: localId, conversationId: conversationId, senderId: currentUserId,
        senderName: currentUserName, senderAvatar: currentUserAvatar,
        content: audioUrl, type: MessageType.audio, extra: extra,
      );
      emit(current.copyWith(messages: [...current.messages, localMessage]));
      final String clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
      pendingMessages[clientId] = localId;
      wsClient.sendMessage(conversationId: conversationId, content: audioUrl, type: proto.MessageType.AUDIO, extra: utf8.encode(jsonEncode(extra)), clientId: clientId);
      setupTimeout(clientId, localId, const Duration(seconds: 15));
      return;
    }

    // 正常上传流程
    final String localId = 'local_${nextLocalId()}';
    pendingLocalPaths[localId] = filePath;
    final Map<String, dynamic> audioExtra = {'duration_ms': durationMs, 'file_size': fileSize};
    final Message localMessage = Message.sending(
      localId: localId, conversationId: conversationId, senderId: currentUserId,
      senderName: currentUserName, senderAvatar: currentUserAvatar,
      content: filePath, type: MessageType.audio, extra: audioExtra,
    );
    emit(current.copyWith(messages: [...current.messages, localMessage]));

    try {
      final result = await repository.uploadFile(filePath, hash: hash, onProgress: (p) {
        _log.d('audio progress: ${(p * 100).toInt()}%');
      });

      final String clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
      pendingMessages[clientId] = localId;
      final Map<String, dynamic> extra = {'duration_ms': durationMs, 'file_size': result.fileSize};
      final ChatState latest = state;
      if (latest is ChatLoaded) {
        final List<Message> updated = latest.messages.map((Message m) {
          if (m.id == localId) return m.copyWith(content: result.fileUrl, extra: extra);
          return m;
        }).toList();
        emit(latest.copyWith(messages: updated));
      }
      wsClient.sendMessage(conversationId: conversationId, content: result.fileUrl, type: proto.MessageType.AUDIO, extra: utf8.encode(jsonEncode(extra)), clientId: clientId);
      setupTimeout(clientId, localId, const Duration(seconds: 15));
    } catch (e) {
      _handleQuotaError(e);
      markFailed(localId);
    }
  }

  // ─── 文件下载 ───

  /// 下载文件
  /// [fullUrl] 完整的文件 URL（调用方负责拼接 baseUrl）
  Future<void> downloadFile(String messageId, String fullUrl, String fileName) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final existing = current.fileDownloads[messageId];
    if (existing != null && (existing.status == FileDownloadStatus.downloading || existing.status == FileDownloadStatus.done)) {
      return;
    }

    _emitDownloadUpdate(messageId, const FileDownloadInfo(status: FileDownloadStatus.downloading));

    late final StreamSubscription<FxDownloadEvent> sub;
    sub = FxMedia.download.stream(url: fullUrl, id: fxMediaIdFromUrl(fullUrl), fileName: fileName).listen(
      (FxDownloadEvent event) {
        switch (event) {
          case FxDownloadProgress(:final double progress):
            _emitDownloadUpdate(messageId, FileDownloadInfo(
              status: FileDownloadStatus.downloading, progress: progress,
            ));
          case FxDownloadComplete(:final String localPath):
            _emitDownloadUpdate(messageId, FileDownloadInfo(
              status: FileDownloadStatus.done, progress: 1.0, localPath: localPath,
            ));
            _updateLocalDataInState(messageId, localPath);
            sub.cancel();
          case FxDownloadError(:final Object error):
            final String errMsg = error.toString();
            _emitDownloadUpdate(messageId, FileDownloadInfo(
              status: FileDownloadStatus.error, error: errMsg,
            ));
            // 404 持久化到 localData，避免重进后再次触发无效下载
            if (errMsg.contains('404') || errMsg.contains('Not Found')) {
              _markResourceDeleted(messageId);
            }
            sub.cancel();
        }
      },
      onError: (Object e) {
        _emitDownloadUpdate(messageId, FileDownloadInfo(
          status: FileDownloadStatus.error, error: e.toString(),
        ));
      },
    );
  }

  void _emitDownloadUpdate(String messageId, FileDownloadInfo info) {
    final s = state;
    if (s is! ChatLoaded) return;
    final updated = Map<String, FileDownloadInfo>.from(s.fileDownloads);
    updated[messageId] = info;
    emit(s.copyWith(fileDownloads: updated));
  }

  /// 下载完成后同步更新内存中 Message 的 localData 并持久化
  void _updateLocalDataInState(String messageId, String localPath) {
    final s = state;
    if (s is! ChatLoaded) return;
    final String localDataJson = jsonEncode({
      'path': localPath,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    });
    final List<Message> updated = s.messages.map((Message m) {
      if (m.id == messageId) return m.copyWith(localData: localDataJson);
      return m;
    }).toList();
    emit(s.copyWith(messages: updated));
    // 持久化到数据库
    repository.store?.updateLocalData(messageId, localDataJson);
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }

  /// 秒传命中时直接发送图片消息（无占位消息、无上传进度）
  void _sendDedupImageMessage(ChatLoaded current, String filePath, Map<String, dynamic> existing) {
    final String url = existing['url'] as String;
    final String? thumbUrl = existing['thumb_url'] as String?;
    final int w = existing['width'] as int? ?? 0;
    final int h = existing['height'] as int? ?? 0;
    final int sz = existing['size'] as int? ?? 0;

    final String localId = 'local_${nextLocalId()}';
    pendingLocalPaths[localId] = filePath;
    final Map<String, dynamic> imageExtra = {
      'width': w, 'height': h, 'size': sz,
      'format': url.split('.').last,
      'thumbnail_url': thumbUrl ?? '',
    };
    final Message localMessage = Message.sending(
      localId: localId,
      conversationId: conversationId,
      senderId: currentUserId,
      senderName: currentUserName,
      senderAvatar: currentUserAvatar,
      content: url,
      type: MessageType.image,
      extra: imageExtra,
    );
    emit(current.copyWith(messages: [...current.messages, localMessage]));

    final String clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
    pendingMessages[clientId] = localId;
    wsClient.sendMessage(
      conversationId: conversationId,
      content: url,
      type: proto.MessageType.IMAGE,
      extra: utf8.encode(jsonEncode(imageExtra)),
      clientId: clientId,
    );
    setupTimeout(clientId, localId, const Duration(seconds: 10));
  }

  /// 检查是否是配额不足错误，是则弹提示并返回 true
  bool _handleQuotaError(Object e) {
    if (e is DioException && e.response?.statusCode == 403) {
      final dynamic body = e.response?.data;
      if (body is Map && body['code'] == 'QUOTA_EXCEEDED') {
        final int used = body['used_bytes'] as int? ?? 0;
        final int quota = body['quota_bytes'] as int? ?? 0;
        ShowToastEvent('云空间不足（已用 ${_formatSize(used)} / ${_formatSize(quota)}）').emit();
        return true;
      }
    }
    return false;
  }
  /// 检查是否是 Broken pipe 类网络断开错误
  bool _isBrokenPipe(Object e) {
    if (e is DioException) {
      final String msg = e.error?.toString() ?? '';
      return msg.contains('Broken pipe') || msg.contains('Connection reset') || msg.contains('Connection closed');
    }
    return false;
  }

  /// 将资源已删除状态持久化到 localData
  void _markResourceDeleted(String messageId) {
    final ChatState s = state;
    if (s is! ChatLoaded) return;
    final String localDataJson = jsonEncode({'deleted': true});
    final List<Message> updated = s.messages.map((Message m) {
      if (m.id == messageId) return m.copyWith(localData: localDataJson);
      return m;
    }).toList();
    emit(s.copyWith(messages: updated));
    repository.store?.updateLocalData(messageId, localDataJson);
  }
}

/// 文件/音频超限异常
class FileSizeExceedException implements Exception {
  final String message;
  const FileSizeExceedException(this.message);
  @override
  String toString() => message;
}
