import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_im_core/flash_im_core.dart' hide MessageStatus, MessageType;
import 'package:flash_im_cache/flash_im_cache.dart';
import '../data/i_message_repository.dart';
import '../data/message.dart';
import 'chat_file_mixin.dart';
import 'chat_pin_mixin.dart';
import 'chat_select_mixin.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> with ChatFileMixin, ChatPinMixin, ChatSelectMixin {
  final IMessageRepository _repository;
  final WsClient _wsClient;
  @override
  final String conversationId;
  @override
  final String currentUserId;
  @override
  final String currentUserName;
  @override
  final String? currentUserAvatar;
  final bool isGroup;
  @override
  final VoidCallback? onConversationChanged;

  StreamSubscription? _chatMessageSub;
  StreamSubscription? _messageAckSub;
  StreamSubscription? _messageRecalledSub;
  StreamSubscription? _pinChangedSub;
  final Map<String, String> _pendingMessages = {};
  int _localIdCounter = 0;
  final LocalStore? _store;

  int _peerReadSeq = 0;
  Map<String, int> _membersReadSeq = {};
  Timer? _readReceiptTimer;
  StreamSubscription? _readReceiptSub;
  int _readSeqVersion = 0;

  int get peerReadSeq => _peerReadSeq;
  Map<String, int> get membersReadSeq => Map.unmodifiable(_membersReadSeq);

  // ─── Mixin 需要的 getter / 方法实现 ───

  @override
  IMessageRepository get repository => _repository;

  @override
  WsClient get wsClient => _wsClient;

  @override
  Map<String, String> get pendingMessages => _pendingMessages;

  @override
  LocalStore? get localStore => _store ?? _repository.store;

  @override
  int nextLocalId() => ++_localIdCounter;

  @override
  void setupTimeout(String clientId, String localId, Duration timeout) {
    Future.delayed(timeout, () {
      if (_pendingMessages.containsKey(clientId)) {
        _pendingMessages.remove(clientId);
        markFailed(localId);
      }
    });
  }

  @override
  void markFailed(String localId) {
    final s = state;
    if (s is ChatLoaded) {
      final updated = s.messages.map((m) =>
        m.id == localId ? m.copyWith(status: MessageStatus.failed) : m
      ).toList();
      emit(s.copyWith(messages: updated, clearUploadProgress: true));
    }
  }

  @override
  void syncConversationPreview(LocalStore store, List<Message> messages) {
    if (messages.isEmpty) {
      store.updateConversation(conversationId, lastMessagePreview: '');
      onConversationChanged?.call();
      return;
    }
    final last = messages.last;
    final preview = last.isRecalled
        ? (last.senderId == currentUserId ? '你撤回了一条消息' : '${last.senderName}撤回了一条消息')
        : last.isText ? last.content
        : last.isImage ? '[图片]'
        : last.isVideo ? '[视频]'
        : last.isFile ? '[文件]'
        : last.content;
    store.updateConversation(conversationId,
      lastMessagePreview: preview,
      lastMessageAt: last.createdAt.millisecondsSinceEpoch,
    );
    onConversationChanged?.call();
  }

  ChatCubit({
    required IMessageRepository repository,
    required WsClient wsClient,
    required this.conversationId,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatar,
    this.isGroup = false,
    this.onConversationChanged,
    LocalStore? store,
  })  : _repository = repository,
        _wsClient = wsClient,
        _store = store,
        super(const ChatInitial()) {
    _chatMessageSub = _wsClient.chatMessageStream.listen(_handleIncomingMessage);
    _messageAckSub = _wsClient.messageAckStream.listen(_handleMessageAck);
    _messageRecalledSub = _wsClient.messageRecalledStream.listen(handleMessageRecalled);
    _pinChangedSub = _wsClient.pinChangedStream.listen((_) => loadPinnedMessages());
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
      loadPinnedMessages();
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

  void sendMessage(String content, {List<Map<String, dynamic>>? mentions}) {
    if (content.trim().isEmpty) return;
    final current = state;
    if (current is! ChatLoaded) return;

    final clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
    final localId = 'local_${++_localIdCounter}';

    // 构建引用回复 extra
    Map<String, dynamic>? extra;
    if (current.replyTo != null) {
      final reply = current.replyTo!;
      extra = {
        'reply_to': {
          'message_id': reply.id,
          'sender_name': reply.senderName,
          'content': reply.isText ? (reply.content.length > 30 ? '${reply.content.substring(0, 30)}...' : reply.content)
              : reply.isImage ? '[图片]' : reply.isVideo ? '[视频]' : reply.isFile ? '[文件]' : reply.content,
          'msg_type': reply.type.index,
        },
      };
    }

    // 合并 @mentions
    if (mentions != null && mentions.isNotEmpty) {
      extra = (extra ?? {})..['mentions'] = mentions;
    }

    // 群聊引用回复时，静默 @被引用者
    if (isGroup && current.replyTo != null && current.replyTo!.senderId != currentUserId) {
      final replySenderId = current.replyTo!.senderId;
      final existingMentions = (extra?['mentions'] as List?) ?? [];
      final alreadyMentioned = existingMentions.any((m) => m['user_id'] == replySenderId);
      if (!alreadyMentioned) {
        existingMentions.add({'user_id': replySenderId, 'offset': -1, 'length': 0});
        extra = (extra ?? {})..['mentions'] = existingMentions;
      }
    }

    final localMessage = Message.sending(
      localId: localId,
      conversationId: conversationId,
      senderId: currentUserId,
      senderName: currentUserName,
      senderAvatar: currentUserAvatar,
      content: content,
      extra: extra,
    );

    emit(current.copyWith(messages: [...current.messages, localMessage], clearReplyTo: true));
    _pendingMessages[clientId] = localId;

    final List<int>? extraBytes = extra != null ? utf8.encode(jsonEncode(extra)) : null;
    _wsClient.sendMessage(
      conversationId: conversationId,
      content: content,
      clientId: clientId,
      extra: extraBytes,
    );

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
        5 => MessageType.forward,
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

  // ─── 引用回复 ───

  void setReplyTo(Message message) {
    final s = state;
    if (s is ChatLoaded) emit(s.copyWith(replyTo: message));
  }

  void clearReplyTo() {
    final s = state;
    if (s is ChatLoaded) emit(s.copyWith(clearReplyTo: true));
  }

  // ─── 转发 ───

  Future<void> forwardMessages({
    required List<String> messageIds,
    required String targetConvId,
    required String forwardType,
  }) async {
    await _repository.forwardMessage(
      sourceConvId: conversationId,
      messageIds: messageIds,
      targetConvId: targetConvId,
      forwardType: forwardType,
    );
  }

  // ─── 复制与删除 ───

  void copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
  }

  Future<void> deleteMessage(String messageId) async {
    final s = state;
    final store = _store ?? _repository.store;
    if (s is! ChatLoaded || store == null) return;
    await store.moveToTrash(messageId, 'message');
    final updated = s.messages.where((m) => m.id != messageId).toList();
    emit(s.copyWith(messages: updated));
    syncConversationPreview(store, updated);
  }

  @override
  Future<void> close() {
    _chatMessageSub?.cancel();
    _messageAckSub?.cancel();
    _messageRecalledSub?.cancel();
    _pinChangedSub?.cancel();
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
