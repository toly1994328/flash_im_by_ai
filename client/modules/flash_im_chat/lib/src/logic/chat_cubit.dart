import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_im_core/flash_im_core.dart' hide MessageStatus;
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

  StreamSubscription? _chatMessageSub;
  StreamSubscription? _messageAckSub;
  final Map<String, String> _pendingMessages = {};
  int _localIdCounter = 0;

  ChatCubit({
    required MessageRepository repository,
    required WsClient wsClient,
    required this.conversationId,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatar,
  })  : _repository = repository,
        _wsClient = wsClient,
        super(const ChatInitial()) {
    _chatMessageSub = _wsClient.chatMessageStream.listen(_handleIncomingMessage);
    _messageAckSub = _wsClient.messageAckStream.listen(_handleMessageAck);
  }

  Future<void> loadMessages() async {
    emit(const ChatLoading());
    try {
      final messages = await _repository.getMessages(conversationId);
      messages.sort((a, b) => a.seq.compareTo(b.seq));
      emit(ChatLoaded(messages: messages, hasMore: messages.length >= 50));
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

    // 10s 超时
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

      final message = Message(
        id: chatMsg.id,
        conversationId: chatMsg.conversationId,
        senderId: chatMsg.senderId,
        senderName: chatMsg.senderName,
        senderAvatar: chatMsg.senderAvatar.isEmpty ? null : chatMsg.senderAvatar,
        seq: chatMsg.seq.toInt(),
        content: chatMsg.content,
        createdAt: DateTime.fromMillisecondsSinceEpoch(chatMsg.createdAt.toInt()),
      );

      if (current.messages.any((m) => m.id == message.id)) return;

      final updated = [...current.messages, message];
      updated.sort((a, b) => a.seq.compareTo(b.seq));
      emit(current.copyWith(messages: updated));
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

      final updated = current.messages.map((m) {
        if (m.id == localId) {
          return m.copyWith(id: ack.messageId, seq: ack.seq.toInt(), status: MessageStatus.sent);
        }
        return m;
      }).toList();
      updated.sort((a, b) => a.seq.compareTo(b.seq));
      emit(current.copyWith(messages: updated));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _chatMessageSub?.cancel();
    _messageAckSub?.cancel();
    return super.close();
  }
}
