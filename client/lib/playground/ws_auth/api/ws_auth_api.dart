import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../config.dart';

/// 认证 WebSocket 连接状态
enum WsAuthStatus { disconnected, connecting, authenticating, authenticated }

/// 带 JWT 认证的 WebSocket 通信层
class WsAuthApi {
  WebSocketChannel? _channel;
  WsAuthStatus _status = WsAuthStatus.disconnected;

  WsAuthStatus get status => _status;

  /// 连接 /ws/auth 并发送 Token 认证
  Stream<Map<String, dynamic>> connect(String token) async* {
    yield* _connectTo('/ws/auth', token);
  }

  /// 连接 /ws/chat_room 并发送 Token 认证
  Stream<Map<String, dynamic>> connectChatRoom(String token) async* {
    yield* _connectTo('/ws/chat_room', token);
  }

  /// 通用：连接指定路径并完成首消息认证
  Stream<Map<String, dynamic>> _connectTo(String path, String token) async* {
    _status = WsAuthStatus.connecting;
    final uri = Uri.parse(
      'ws://${PlaygroundConfig.host}:${PlaygroundConfig.port}$path',
    );
    _channel = WebSocketChannel.connect(uri);
    await _channel!.ready;

    // 发送首消息认证
    _status = WsAuthStatus.authenticating;
    _channel!.sink.add(jsonEncode({'token': token}));

    await for (final raw in _channel!.stream) {
      final data = jsonDecode(raw.toString()) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'auth_ok') {
        _status = WsAuthStatus.authenticated;
      } else if (type == 'auth_fail' || type == 'auth_timeout') {
        _status = WsAuthStatus.disconnected;
        _channel = null;
      }

      yield data;
    }

    // 流结束 = 连接断开
    _status = WsAuthStatus.disconnected;
    _channel = null;
  }

  /// 发送文本消息
  void send(String text) {
    _channel?.sink.add(text);
  }

  /// 断开连接
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _status = WsAuthStatus.disconnected;
  }
}
