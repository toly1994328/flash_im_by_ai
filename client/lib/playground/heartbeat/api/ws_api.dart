import 'package:web_socket_channel/web_socket_channel.dart';
import '../../config.dart';

/// 连接状态
enum WsStatus { disconnected, connecting, connected }

/// WebSocket 通信层
class WsApi {
  WebSocketChannel? _channel;
  WsStatus _status = WsStatus.disconnected;

  WsStatus get status => _status;

  /// 建立连接，返回消息流
  Stream<dynamic> connect() {
    _status = WsStatus.connecting;
    final uri = Uri.parse(
      'ws://${PlaygroundConfig.host}:${PlaygroundConfig.port}/ws',
    );
    _channel = WebSocketChannel.connect(uri);

    _channel!.ready.then((_) => _status = WsStatus.connected);

    return _channel!.stream;
  }

  /// 发送文本消息
  void send(String text) {
    _channel?.sink.add(text);
  }

  /// 断开连接
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _status = WsStatus.disconnected;
  }
}
