/// WebSocket 消息实体
class WsMessage {
  final String text;
  final bool isMe; // true=我发的, false=服务端回的
  final DateTime time;

  const WsMessage({
    required this.text,
    required this.isMe,
    required this.time,
  });

  @override
  String toString() => '${isMe ? "→" : "←"} $text';
}
