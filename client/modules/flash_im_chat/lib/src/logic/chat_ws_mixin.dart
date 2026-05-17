import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_im_core/flash_im_core.dart' hide MessageStatus, MessageType;

import 'chat_state.dart';

/// WS 订阅管理 Mixin。
///
/// 集中管理所有 WebSocket stream 的注册和取消，
/// 通过抽象回调将事件分发给具体实现。
mixin ChatWsMixin on Cubit<ChatState> {
  final List<StreamSubscription> _wsSubs = [];

  WsClient get wsClient;

  // ─── 抽象回调，由 ChatCubit 或其他 mixin 实现 ───

  void onChatMessage(WsFrame frame);
  void onMessageAck(WsFrame frame);
  void onMessageRecalled(WsFrame frame);
  void onPinChanged(WsFrame frame);
  void onReadReceipt(WsFrame frame);

  // ─── 生命周期 ───

  /// 注册所有 WS stream 监听。构造函数中调用一次。
  void initWsListeners() {
    _wsSubs.addAll([
      wsClient.chatMessageStream.listen(onChatMessage),
      wsClient.messageAckStream.listen(onMessageAck),
      wsClient.messageRecalledStream.listen(onMessageRecalled),
      wsClient.pinChangedStream.listen(onPinChanged),
      wsClient.readReceiptStream.listen(onReadReceipt),
    ]);
  }

  /// 取消所有 WS stream 监听。close 中调用。
  void disposeWsListeners() {
    for (final sub in _wsSubs) {
      sub.cancel();
    }
    _wsSubs.clear();
  }
}
