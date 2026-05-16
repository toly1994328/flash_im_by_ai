import 'dart:async';

import 'package:flash_im_core/flash_im_core.dart';
import 'package:flash_im_core/flash_im_core.dart' as proto show MessageType;

/// 测试用的 WsClient 替身。
///
/// 暴露 StreamController，测试代码可精确控制事件时序。
/// 记录发送的消息，供断言验证。
class FakeWsClient extends WsClient {
  final chatMessageController = StreamController<WsFrame>.broadcast();
  final messageAckController = StreamController<WsFrame>.broadcast();
  final messageRecalledController = StreamController<WsFrame>.broadcast();
  final pinChangedController = StreamController<WsFrame>.broadcast();
  final readReceiptController = StreamController<WsFrame>.broadcast();

  /// 记录所有通过 sendMessage 发出的调用
  final List<SentMessage> sentMessages = [];

  /// 记录所有通过 sendReadReceipt 发出的调用
  final List<SentReadReceipt> sentReadReceipts = [];

  FakeWsClient() : super(
    config: ImConfig(wsUrl: 'ws://fake'),
    tokenProvider: () => 'fake_token',
  );

  @override
  Stream<WsFrame> get chatMessageStream => chatMessageController.stream;

  @override
  Stream<WsFrame> get messageAckStream => messageAckController.stream;

  @override
  Stream<WsFrame> get messageRecalledStream => messageRecalledController.stream;

  @override
  Stream<WsFrame> get pinChangedStream => pinChangedController.stream;

  @override
  Stream<WsFrame> get readReceiptStream => readReceiptController.stream;

  @override
  void sendMessage({
    required String conversationId,
    required String content,
    proto.MessageType type = proto.MessageType.TEXT,
    List<int>? extra,
    String? clientId,
  }) {
    sentMessages.add(SentMessage(
      conversationId: conversationId,
      content: content,
      type: type,
      extra: extra,
      clientId: clientId,
    ));
  }

  @override
  void sendReadReceipt({required String conversationId, required int readSeq}) {
    sentReadReceipts.add(SentReadReceipt(
      conversationId: conversationId,
      readSeq: readSeq,
    ));
  }

  @override
  void dispose() {
    chatMessageController.close();
    messageAckController.close();
    messageRecalledController.close();
    pinChangedController.close();
    readReceiptController.close();
  }
}

/// 记录 sendMessage 调用的参数
class SentMessage {
  final String conversationId;
  final String content;
  final proto.MessageType type;
  final List<int>? extra;
  final String? clientId;

  SentMessage({
    required this.conversationId,
    required this.content,
    required this.type,
    this.extra,
    this.clientId,
  });
}

/// 记录 sendReadReceipt 调用的参数
class SentReadReceipt {
  final String conversationId;
  final int readSeq;

  SentReadReceipt({required this.conversationId, required this.readSeq});
}
