import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flash_im_core/flash_im_core.dart' hide MessageStatus, MessageType;
import 'package:flash_im_core/flash_im_core.dart' as proto show MessageType;
import 'package:flash_im_cache/flash_im_cache.dart';
import '../data/message.dart';
import '../data/message_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final MessageRepository _repository;
  final WsClient _wsClient;
  final String conversationId;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserAvatar;
  final bool isGroup;

  StreamSubscription? _chatMessageSub;
  StreamSubscription? _messageAckSub;
  final Map<String, String> _pendingMessages = {};
  int _localIdCounter = 0;

  int _peerReadSeq = 0;
  Map<String, int> _membersReadSeq = {};
  Timer? _readReceiptTimer;
  StreamSubscription? _readReceiptSub;
  int _readSeqVersion = 0;

  int get peerReadSeq => _peerReadSeq;
  Map<String, int> get membersReadSeq => Map.unmodifiable(_membersReadSeq);

  ChatCubit({
    required MessageRepository repository,
    required WsClient wsClient,
    required this.conversationId,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatar,
    this.isGroup = false,
  })  : _repository = repository,
        _wsClient = wsClient,
        super(const ChatInitial()) {
    _chatMessageSub = _wsClient.chatMessageStream.listen(_handleIncomingMessage);
    _messageAckSub = _wsClient.messageAckStream.listen(_handleMessageAck);
    _readReceiptSub = _wsClient.readReceiptStream.listen((frame) {
      final notif = ReadReceiptNotification.fromBuffer(frame.payload);
      if (notif.conversationId != conversationId) return;
      if (isGroup) {
        _membersReadSeq[notif.userId] = notif.readSeq.toInt();
      } else {
        _peerReadSeq = notif.readSeq.toInt();
      }
      final s = state;
      if (s is ChatLoaded) emit(s.copyWith(readSeqVersion: ++_readSeqVersion));
    });
  }

  Future<void> loadMessages() async {
    emit(const ChatLoading());
    try {
      final messages = await _repository.getMessages(conversationId);
      messages.sort((a, b) => a.seq.compareTo(b.seq));
      emit(ChatLoaded(messages: messages, hasMore: messages.length >= 50));
      _loadReadSeq();
      final maxSeq = messages.isNotEmpty ? messages.last.seq : 0;
      _reportReadSeq(maxSeq);
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! ChatLoaded || !current.hasMore || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final oldestSeq = current.messages.isNotEmpty ? current.messages.first.seq : null;
      if (oldestSeq != null && oldestSeq <= 1) {
        emit(current.copyWith(hasMore: false, isLoadingMore: false));
        return;
      }
      final more = await _repository.getMessages(conversationId, beforeSeq: oldestSeq);
      final existingIds = current.messages.map((m) => m.id).toSet();
      final newMessages = more.where((m) => !existingIds.contains(m.id)).toList();
      final all = [...newMessages, ...current.messages];
      all.sort((a, b) => a.seq.compareTo(b.seq));
      emit(current.copyWith(
        messages: all,
        hasMore: newMessages.isNotEmpty && (all.isNotEmpty && all.first.seq > 1),
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  void sendMessage(String content) {
    if (content.trim().isEmpty) return;
    final current = state;
    if (current is! ChatLoaded) return;

    final clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
    final localId = 'local_${++_localIdCounter}';

    final localMessage = Message.sending(
      localId: localId,
      conversationId: conversationId,
      senderId: currentUserId,
      senderName: currentUserName,
      senderAvatar: currentUserAvatar,
      content: content,
    );

    emit(current.copyWith(messages: [...current.messages, localMessage]));
    _pendingMessages[clientId] = localId;
    _wsClient.sendMessage(conversationId: conversationId, content: content, clientId: clientId);

    Future.delayed(const Duration(seconds: 10), () {
      if (_pendingMessages.containsKey(clientId)) {
        _pendingMessages.remove(clientId);
        final s = state;
        if (s is ChatLoaded) {
          final updated = s.messages.map((m) =>
            m.id == localId ? m.copyWith(status: MessageStatus.failed) : m
          ).toList();
          emit(s.copyWith(messages: updated));
        }
      }
    });
  }

  /// 从本地文件发送图片消�?
  Future<void> sendImageFromFile(String filePath) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final localId = 'local_${++_localIdCounter}';
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
      final result = await _repository.uploadImage(filePath, onProgress: (p) {
        print('📤 [upload] image progress: ${(p * 100).toInt()}%');
        final s = state;
        if (s is ChatLoaded) emit(s.copyWith(uploadProgress: p));
      });

      final afterUpload = state;
      if (afterUpload is ChatLoaded) {
        emit(afterUpload.copyWith(clearUploadProgress: true));
      }

      // 不更新 content（保持本地路径，UI 始终显示本地图片）
      // 只记录 extra 供 ACK 后使用
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
      _pendingMessages[clientId] = localId;
      _wsClient.sendMessage(
        conversationId: conversationId,
        content: result.originalUrl,
        type: proto.MessageType.IMAGE,
        extra: utf8.encode(jsonEncode(imageExtra)),
        clientId: clientId,
      );

      _setupTimeout(clientId, localId, const Duration(seconds: 10));
    } catch (e) {
      _markFailed(localId);
    }
  }

  /// 从本地文件发送视频消�?
  Future<void> sendVideoFromFile(String filePath, String thumbnailPath, int durationMs, {int width = 0, int height = 0}) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final localId = 'local_${++_localIdCounter}';
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
      final result = await _repository.uploadVideo(
        filePath, thumbnailPath, durationMs,
        width: width, height: height,
        onProgress: (p) {
          print('📤 [upload] video progress: ${(p * 100).toInt()}%');
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
      _pendingMessages[clientId] = localId;
      _wsClient.sendMessage(
        conversationId: conversationId,
        content: result.videoUrl,
        type: proto.MessageType.VIDEO,
        extra: utf8.encode(jsonEncode(videoExtra.toJson())),
        clientId: clientId,
      );

      _setupTimeout(clientId, localId, const Duration(seconds: 30));
    } catch (e) {
      _markFailed(localId);
    }
  }

  /// 从文件选择器发送文件消�?
  Future<void> sendFileFromPicker(String filePath) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final localId = 'local_${++_localIdCounter}';
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
      final result = await _repository.uploadFile(filePath, onProgress: (p) {
        print('📤 [upload] file progress: ${(p * 100).toInt()}%');
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
      _pendingMessages[clientId] = localId;
      _wsClient.sendMessage(
        conversationId: conversationId,
        content: result.fileUrl,
        type: proto.MessageType.FILE,
        extra: utf8.encode(jsonEncode(fileExtra.toJson())),
        clientId: clientId,
      );

      _setupTimeout(clientId, localId, const Duration(seconds: 30));
    } catch (e) {
      _markFailed(localId);
    }
  }

  void _handleIncomingMessage(WsFrame frame) {
    try {
      final chatMsg = ChatMessage.fromBuffer(frame.payload);
      if (chatMsg.conversationId != conversationId) return;
      if (chatMsg.senderId == currentUserId) return;

      final current = state;
      if (current is! ChatLoaded) return;

      final msgType = switch (chatMsg.type.value) {
        1 => MessageType.image,
        2 => MessageType.video,
        3 => MessageType.file,
        _ => MessageType.text,
      };

      Map<String, dynamic>? extra;
      if (chatMsg.extra.isNotEmpty) {
        try { extra = jsonDecode(utf8.decode(chatMsg.extra)) as Map<String, dynamic>?; } catch (_) {}
      }

      final message = Message(
        id: chatMsg.id,
        conversationId: chatMsg.conversationId,
        senderId: chatMsg.senderId,
        senderName: chatMsg.senderName,
        senderAvatar: chatMsg.senderAvatar.isEmpty ? null : chatMsg.senderAvatar,
        seq: chatMsg.seq.toInt(),
        content: chatMsg.content,
        createdAt: DateTime.fromMillisecondsSinceEpoch(chatMsg.createdAt.toInt()),
        type: msgType,
        extra: extra,
      );

      if (current.messages.any((m) => m.id == message.id)) return;

      final updated = [...current.messages, message];
      updated.sort((a, b) => a.seq.compareTo(b.seq));
      emit(current.copyWith(messages: updated));
      _reportReadSeq(message.seq);
    } catch (_) {}
  }

  void _handleMessageAck(WsFrame frame) {
    try {
      final ack = MessageAck.fromBuffer(frame.payload);
      if (_pendingMessages.isEmpty) return;

      final current = state;
      if (current is! ChatLoaded) return;

      final entry = _pendingMessages.entries.first;
      final localId = entry.value;
      _pendingMessages.remove(entry.key);

      Message? confirmedMessage;
      final updated = current.messages.map((m) {
        if (m.id == localId) {
          confirmedMessage = m.copyWith(id: ack.messageId, seq: ack.seq.toInt(), status: MessageStatus.sent);
          return confirmedMessage!;
        }
        return m;
      }).toList();
      updated.sort((a, b) => a.seq.compareTo(b.seq));
      emit(current.copyWith(messages: updated));

      // 写入本地缓存，确保退出重进后自发消息不丢失
      final store = _repository.store;
      if (confirmedMessage != null && store != null) {
        final msg = confirmedMessage!;
        final cached = CachedMessage(
          id: msg.id,
          conversationId: msg.conversationId,
          senderId: msg.senderId,
          senderName: msg.senderName,
          senderAvatar: msg.senderAvatar,
          seq: msg.seq,
          msgType: msg.type.index,
          content: msg.content,
          extra: msg.extra != null ? jsonEncode(msg.extra) : null,
          createdAt: msg.createdAt.millisecondsSinceEpoch,
        );
        store.cacheMessages([cached], conversationId: msg.conversationId);
      }
    } catch (_) {}
  }

  void _setupTimeout(String clientId, String localId, Duration timeout) {
    Future.delayed(timeout, () {
      if (_pendingMessages.containsKey(clientId)) {
        _pendingMessages.remove(clientId);
        _markFailed(localId);
      }
    });
  }

  void _markFailed(String localId) {
    final s = state;
    if (s is ChatLoaded) {
      final updated = s.messages.map((m) =>
        m.id == localId ? m.copyWith(status: MessageStatus.failed) : m
      ).toList();
      emit(s.copyWith(messages: updated, clearUploadProgress: true));
    }
  }

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

      await _repository.downloadFile(fullUrl, savePath, onProgress: (p) {
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

  @override
  Future<void> close() {
    _chatMessageSub?.cancel();
    _messageAckSub?.cancel();
    _readReceiptSub?.cancel();
    _readReceiptTimer?.cancel();
    return super.close();
  }

  Future<void> _loadReadSeq() async {
    try {
      final res = await _repository.getReadSeq(conversationId);
      if (isGroup) {
        _membersReadSeq = res;
      } else if (res.isNotEmpty) {
        _peerReadSeq = res.values.first;
      }
      final s = state;
      if (s is ChatLoaded) emit(s.copyWith(readSeqVersion: ++_readSeqVersion));
    } catch (_) {}
  }

  void _reportReadSeq(int maxSeq) {
    if (maxSeq <= 0) return;
    _readReceiptTimer?.cancel();
    _readReceiptTimer = Timer(const Duration(seconds: 1), () {
      _wsClient.sendReadReceipt(conversationId: conversationId, readSeq: maxSeq);
    });
  }
}
