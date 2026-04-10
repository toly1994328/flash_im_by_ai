import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../data/im_config.dart';
import '../data/proto/ws.pb.dart';
import '../data/proto/ws.pbenum.dart';
import '../data/proto/message.pb.dart' as msg;

typedef TokenProvider = String? Function();

/// WebSocket 连接状态
enum WsConnectionState {
  disconnected,
  connecting,
  authenticating,
  authenticated,
}

/// WebSocket 管理器
///
/// 负责连接、Protobuf 帧认证、心跳保活、断线重连、帧收发。
/// 会话级对象：登录后创建，退出时销毁。
class WsClient {
  final ImConfig _config;
  final TokenProvider _tokenProvider;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  int _reconnectAttempts = 0;
  int _missedPongs = 0;
  bool _intentionalDisconnect = false;
  WsConnectionState _state = WsConnectionState.disconnected;

  final _stateController = StreamController<WsConnectionState>.broadcast();
  Stream<WsConnectionState> get stateStream => _stateController.stream;
  WsConnectionState get state => _state;

  final _frameController = StreamController<WsFrame>.broadcast();
  Stream<WsFrame> get frameStream => _frameController.stream;

  final _chatMessageController = StreamController<WsFrame>.broadcast();
  final _messageAckController = StreamController<WsFrame>.broadcast();
  final _conversationUpdateController = StreamController<WsFrame>.broadcast();

  Stream<WsFrame> get chatMessageStream => _chatMessageController.stream;
  Stream<WsFrame> get messageAckStream => _messageAckController.stream;
  Stream<WsFrame> get conversationUpdateStream => _conversationUpdateController.stream;

  final _friendRequestController = StreamController<WsFrame>.broadcast();
  final _friendAcceptedController = StreamController<WsFrame>.broadcast();
  final _friendRemovedController = StreamController<WsFrame>.broadcast();

  Stream<WsFrame> get friendRequestStream => _friendRequestController.stream;
  Stream<WsFrame> get friendAcceptedStream => _friendAcceptedController.stream;
  Stream<WsFrame> get friendRemovedStream => _friendRemovedController.stream;

  WsClient({
    required ImConfig config,
    required TokenProvider tokenProvider,
  })  : _config = config,
        _tokenProvider = tokenProvider;

  void _setState(WsConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// 建立连接并自动认证
  Future<void> connect() async {
    if (_state == WsConnectionState.authenticated ||
        _state == WsConnectionState.connecting ||
        _state == WsConnectionState.authenticating) {
      return;
    }

    _intentionalDisconnect = false;
    _setState(WsConnectionState.connecting);

    try {
      final channel = WebSocketChannel.connect(Uri.parse(_config.wsUrl));
      await channel.ready;
      _channel = channel;

      _setState(WsConnectionState.authenticating);

      // 发送 AUTH 帧
      final token = _tokenProvider() ?? '';
      final authReq = AuthRequest()..token = token;
      final frame = WsFrame()
        ..type = WsFrameType.AUTH
        ..payload = authReq.writeToBuffer();
      _channel!.sink.add(frame.writeToBuffer());

      // 监听消息
      _subscription = _channel!.stream.listen(
        _onData,
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
      );
    } catch (_) {
      _onDisconnected();
    }
  }

  void _onData(dynamic raw) {
    final Uint8List bytes;
    if (raw is Uint8List) {
      bytes = raw;
    } else if (raw is List<int>) {
      bytes = Uint8List.fromList(raw);
    } else {
      return;
    }

    final WsFrame frame;
    try {
      frame = WsFrame.fromBuffer(bytes);
    } catch (_) {
      return;
    }

    // 认证阶段：等待 AUTH_RESULT
    if (_state == WsConnectionState.authenticating) {
      if (frame.type == WsFrameType.AUTH_RESULT) {
        final result = AuthResult.fromBuffer(frame.payload);
        if (result.success) {
          _reconnectAttempts = 0;
          _setState(WsConnectionState.authenticated);
          _startHeartbeat();
        } else {
          _setState(WsConnectionState.disconnected);
          _cleanup();
        }
      }
      return;
    }

    // 已认证：处理帧
    if (frame.type == WsFrameType.PONG) {
      _missedPongs = 0;
      print('💓 [WsClient] PONG received ${DateTime.now()}');
      return;
    }

    // 按类型分发
    switch (frame.type) {
      case WsFrameType.CHAT_MESSAGE:
        _chatMessageController.add(frame);
      case WsFrameType.MESSAGE_ACK:
        _messageAckController.add(frame);
      case WsFrameType.CONVERSATION_UPDATE:
        _conversationUpdateController.add(frame);
      case WsFrameType.FRIEND_REQUEST:
        _friendRequestController.add(frame);
      case WsFrameType.FRIEND_ACCEPTED:
        _friendAcceptedController.add(frame);
      case WsFrameType.FRIEND_REMOVED:
        _friendRemovedController.add(frame);
      default:
        break;
    }
    _frameController.add(frame);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _missedPongs = 0;
    _heartbeatTimer = Timer.periodic(_config.heartbeatInterval, (_) {
      if (_state != WsConnectionState.authenticated) return;

      final ping = WsFrame()
        ..type = WsFrameType.PING
        ..payload = [];
      sendFrame(ping);
      print('💓 [WsClient] PING sent (missed: $_missedPongs) ${DateTime.now()}');

      _missedPongs++;
      if (_missedPongs >= _config.heartbeatTimeout) {
        _onDisconnected();
      }
    });
  }

  void _onDisconnected() {
    _cleanup();
    _setState(WsConnectionState.disconnected);

    if (_intentionalDisconnect) return;

    // 指数退避重连
    final delay = Duration(
      milliseconds: min(
        _config.reconnectBaseDelay.inMilliseconds *
            pow(2, _reconnectAttempts).toInt(),
        _config.reconnectMaxDelay.inMilliseconds,
      ),
    );
    _reconnectAttempts++;
    _reconnectTimer = Timer(delay, connect);
  }

  void _cleanup() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// 发送帧
  void sendFrame(WsFrame frame) {
    _channel?.sink.add(frame.writeToBuffer());
  }

  /// 发送聊天消息
  void sendMessage({
    required String conversationId,
    required String content,
    msg.MessageType type = msg.MessageType.TEXT,
    List<int>? extra,
    String? clientId,
  }) {
    final req = msg.SendMessageRequest()
      ..conversationId = conversationId
      ..type = type
      ..content = content
      ..clientId = clientId ?? '';
    if (extra != null) req.extra = extra;
    final frame = WsFrame()
      ..type = WsFrameType.CHAT_MESSAGE
      ..payload = req.writeToBuffer();
    sendFrame(frame);
  }

  /// 主动断开连接，不触发重连
  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cleanup();
    _setState(WsConnectionState.disconnected);
  }

  /// 释放所有资源
  void dispose() {
    disconnect();
    _stateController.close();
    _frameController.close();
    _chatMessageController.close();
    _messageAckController.close();
    _conversationUpdateController.close();
    _friendRequestController.close();
    _friendAcceptedController.close();
    _friendRemovedController.close();
  }
}
