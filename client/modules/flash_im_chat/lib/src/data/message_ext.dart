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

/// Message 显示相关扩展
extension MessageDisplayExt on Message {
  /// 消息内容摘要（用于回复预览等场景）
  String get contentSummary => switch (type) {
    MessageType.text => content,
    MessageType.image => '[图片]',
    MessageType.video => '[视频]',
    MessageType.audio => '[语音]',
    _ => '[文件]',
  };
}
