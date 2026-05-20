import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fx_logger/fx_logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flash_im_core/flash_im_core.dart' hide MessageStatus, MessageType;
import 'package:flash_im_core/flash_im_core.dart' as proto show MessageType;

import '../data/i_message_repository.dart';
import '../data/message.dart';
import 'chat_state.dart';

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
  int nextLocalId();
  void setupTimeout(String clientId, String localId, Duration timeout);
  void markFailed(String localId);

  // ─── 图片发送 ───

  /// 从本地文件发送图片消息
  Future<void> sendImageFromFile(String filePath) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final localId = 'local_${nextLocalId()}';
    final localFileSize = await File(filePath).length();
    final localMessage = Message.sending(
      localId: localId,
      conversationId: conversationId,
      senderId: currentUserId,
      senderName: currentUserName,
      senderAvatar: currentUserAvatar,
      content: filePath,
      type: MessageType.image,
      extra: {'size': localFileSize},
    );
    emit(current.copyWith(messages: [...current.messages, localMessage]));

    try {
      final result = await repository.uploadImage(filePath, onProgress: (p) {
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
      if (latest is ChatLoaded) {
        final updated = latest.messages.map((m) {
          if (m.id == localId) {
            return m.copyWith(extra: imageExtra);
          }
          return m;
        }).toList();
        emit(latest.copyWith(messages: updated));
      }

      final clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
      pendingMessages[clientId] = localId;
      wsClient.sendMessage(
        conversationId: conversationId,
        content: result.originalUrl,
        type: proto.MessageType.IMAGE,
        extra: utf8.encode(jsonEncode(imageExtra)),
        clientId: clientId,
      );

      setupTimeout(clientId, localId, const Duration(seconds: 10));
    } catch (e) {
      markFailed(localId);
    }
  }

  // ─── 视频发送 ───

  /// 从本地文件发送视频消息
  Future<void> sendVideoFromFile(String filePath, String thumbnailPath, int durationMs, {int width = 0, int height = 0}) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final localId = 'local_${nextLocalId()}';
    final localMessage = Message.sending(
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
        width: width, height: height,
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
        final updated = latest.messages.map((m) {
          if (m.id == localId) {
            return m.copyWith(extra: videoExtra.toJson());
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
      markFailed(localId);
    }
  }

  // ─── 文件发送 ───

  /// 从文件选择器发送文件消息
  Future<void> sendFileFromPicker(String filePath) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final localId = 'local_${nextLocalId()}';
    final fileName = filePath.split('/').last.split('\\').last;
    final fileSize = await File(filePath).length();

    final localMessage = Message.sending(
      localId: localId,
      conversationId: conversationId,
      senderId: currentUserId,
      senderName: currentUserName,
      senderAvatar: currentUserAvatar,
      content: fileName,
      type: MessageType.file,
      extra: {'file_name': fileName, 'file_type': fileName.split('.').last, 'file_size': fileSize},
    );
    emit(current.copyWith(messages: [...current.messages, localMessage]));

    try {
      final result = await repository.uploadFile(filePath, onProgress: (p) {
        _log.d('file progress: ${(p * 100).toInt()}%');
        final s = state;
        if (s is ChatLoaded) emit(s.copyWith(uploadProgress: p));
      });

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
      wsClient.sendMessage(
        conversationId: conversationId,
        content: result.fileUrl,
        type: proto.MessageType.FILE,
        extra: utf8.encode(jsonEncode(fileExtra.toJson())),
        clientId: clientId,
      );

      setupTimeout(clientId, localId, const Duration(seconds: 30));
    } catch (e) {
      markFailed(localId);
    }
  }

  // ─── 语音发送 ───

  /// 从录音文件发送语音消息
  Future<void> sendAudioFromFile(String filePath, int durationMs) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final localId = 'local_${nextLocalId()}';
    final fileSize = await File(filePath).length();
    final audioExtra = {'duration_ms': durationMs, 'file_size': fileSize};

    final localMessage = Message.sending(
      localId: localId,
      conversationId: conversationId,
      senderId: currentUserId,
      senderName: currentUserName,
      senderAvatar: currentUserAvatar,
      content: filePath,
      type: MessageType.audio,
      extra: audioExtra,
    );
    emit(current.copyWith(messages: [...current.messages, localMessage]));

    try {
      final result = await repository.uploadFile(filePath, onProgress: (p) {
        _log.d('audio progress: ${(p * 100).toInt()}%');
      });

      final clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
      pendingMessages[clientId] = localId;

      final extra = {'duration_ms': durationMs, 'file_size': result.fileSize};

      final latest = state;
      if (latest is ChatLoaded) {
        final updated = latest.messages.map((m) {
          if (m.id == localId) {
            return m.copyWith(content: result.fileUrl, extra: extra);
          }
          return m;
        }).toList();
        emit(latest.copyWith(messages: updated));
      }

      wsClient.sendMessage(
        conversationId: conversationId,
        content: result.fileUrl,
        type: proto.MessageType.AUDIO,
        extra: utf8.encode(jsonEncode(extra)),
        clientId: clientId,
      );

      setupTimeout(clientId, localId, const Duration(seconds: 15));
    } catch (e) {
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

    try {
      final dir = await _getDownloadDir();
      final savePath = '$dir/$fileName';

      await repository.downloadFile(fullUrl, savePath, onProgress: (p) {
        _emitDownloadUpdate(messageId, FileDownloadInfo(
          status: FileDownloadStatus.downloading, progress: p,
        ));
      });

      _emitDownloadUpdate(messageId, FileDownloadInfo(
        status: FileDownloadStatus.done, progress: 1.0, localPath: savePath,
      ));
    } catch (e) {
      _emitDownloadUpdate(messageId, FileDownloadInfo(
        status: FileDownloadStatus.error, error: e.toString(),
      ));
    }
  }

  void _emitDownloadUpdate(String messageId, FileDownloadInfo info) {
    final s = state;
    if (s is! ChatLoaded) return;
    final updated = Map<String, FileDownloadInfo>.from(s.fileDownloads);
    updated[messageId] = info;
    emit(s.copyWith(fileDownloads: updated));
  }

  Future<String> _getDownloadDir() async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }
}
