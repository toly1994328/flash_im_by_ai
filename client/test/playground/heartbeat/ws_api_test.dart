import 'package:flutter_test/flutter_test.dart';
import 'package:flash_im/playground/heartbeat/api/ws_api.dart';
import 'package:flash_im/playground/heartbeat/model/ws_message.dart';

void main() {
  group('WsApi 连接测试', () {
    late WsApi ws;

    setUp(() {
      ws = WsApi();
    });

    tearDown(() {
      ws.disconnect();
    });

    test('初始状态应为 disconnected', () {
      expect(ws.status, WsStatus.disconnected);
    });

    test('connect 后应收到欢迎消息', () async {
      final stream = ws.connect();
      final first = await stream.first;
      expect(first, contains('欢迎'));
    });

    test('发送消息应收到 echo 回复', () async {
      final stream = ws.connect();
      // 跳过欢迎消息
      final messages = stream.asBroadcastStream();
      await messages.first; // 欢迎消息

      ws.send('hello');
      final reply = await messages.first;
      expect(reply, 'echo: hello');
    });

    test('disconnect 后状态应为 disconnected', () async {
      final stream = ws.connect();
      await stream.first; // 等待连接建立
      ws.disconnect();
      expect(ws.status, WsStatus.disconnected);
    });
  });

  group('WsMessage 模型测试', () {
    test('toString 发送消息显示 →', () {
      final msg = WsMessage(text: 'hello', isMe: true, time: DateTime(2025));
      expect(msg.toString(), '→ hello');
    });

    test('toString 接收消息显示 ←', () {
      final msg = WsMessage(text: 'echo: hello', isMe: false, time: DateTime(2025));
      expect(msg.toString(), '← echo: hello');
    });
  });
}
