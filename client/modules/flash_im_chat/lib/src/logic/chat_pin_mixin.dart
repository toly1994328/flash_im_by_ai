import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_im_cache/flash_im_cache.dart';
import 'package:flash_im_core/flash_im_core.dart' hide MessageStatus, MessageType;
import 'package:flash_im_core/flash_im_core.dart' as proto show MessageRecalled;

import '../data/i_message_repository.dart';
import '../data/message.dart';
import 'chat_state.dart';

/// 消息撤回与置顶的 Mixin。
mixin ChatPinMixin on Cubit<ChatState> {
  // ─── 抽象 getter / 方法，由 ChatCubit 实现 ───

  IMessageRepository get repository;
  String get conversationId;
  String get currentUserId;
  LocalStore? get localStore;
  VoidCallback? get onConversationChanged;

  // ─── 置顶 ───

  Future<void> loadPinnedMessages() async {
    try {
      final data = await repository.getPinnedMessages(conversationId);
      final pinned = data.map((e) => PinnedMessage.fromJson(e)).toList();
      final s = state;
      if (s is ChatLoaded) emit(s.copyWith(pinnedMessages: pinned));
    } catch (_) {}
  }

  Future<void> pinMessage(String messageId) async {
    await repository.pinMessage(conversationId, messageId);
    await loadPinnedMessages();
  }

  Future<void> unpinMessage(String pinId) async {
    await repository.unpinMessage(conversationId, pinId);
    await loadPinnedMessages();
  }

  // ─── 消息撤回 ───

  Future<void> recallMessage(String messageId) async {
    try {
      await repository.recallMessage(conversationId, messageId);
      replaceWithRecalled(messageId, isMe: true);
    } catch (_) {}
  }

  /// 处理收到的撤回帧（WS 监听调用）
  void handleMessageRecalled(WsFrame frame) {
    try {
      final recalled = proto.MessageRecalled.fromBuffer(frame.payload);
      if (recalled.conversationId != conversationId) return;
      replaceWithRecalled(recalled.messageId,
          isMe: recalled.senderId == currentUserId);
    } catch (_) {}
  }

  /// 将指定消息替换为撤回状态
  void replaceWithRecalled(String messageId, {required bool isMe}) {
    final s = state;
    if (s is! ChatLoaded) return;
    Message? recalledMessage;
    final updated = s.messages.map((m) {
      if (m.id == messageId) {
        // 已经被替换过了（幂等），跳过
        if (m.isRecalled) return m;
        final extra = <String, dynamic>{'_recalled': true};
        // 自己撤回的文本消息，保存原始内容供"重新编辑"
        if (isMe && m.type == MessageType.text) {
          extra['_original_content'] = m.content;
        }
        recalledMessage = m.copyWith(
          content: isMe ? '你撤回了一条消息' : '${m.senderName}撤回了一条消息',
          type: MessageType.text,
          extra: extra,
        );
        return recalledMessage!;
      }
      return m;
    }).toList();
    if (recalledMessage == null) return; // 已经处理过，无需后续操作
    emit(s.copyWith(messages: updated));

    // 同步写入本地缓存
    final store = localStore;
    if (recalledMessage != null && store != null) {
      final msg = recalledMessage!;
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
      // 如果撤回的是最后一条消息，更新会话预览
      final s2 = state;
      if (s2 is ChatLoaded) {
        _syncPreviewAfterRecall(store, s2.messages);
      }
    }
  }

  /// 撤回后同步会话预览（内部使用）
  void _syncPreviewAfterRecall(LocalStore store, List<Message> messages) {
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
}
