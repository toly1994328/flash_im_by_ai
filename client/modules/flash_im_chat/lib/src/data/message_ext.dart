import 'dart:convert';

import 'package:flash_im_cache/flash_im_cache.dart';

import 'message.dart';

/// Message 与 CachedMessage 之间的转换扩展。
extension MessageCacheExt on Message {
  CachedMessage toCached() => CachedMessage(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        seq: seq,
        msgType: type.value,
        content: content,
        extra: extra != null ? jsonEncode(extra) : null,
        createdAt: createdAt.millisecondsSinceEpoch,
        localData: localData,
      );
}
