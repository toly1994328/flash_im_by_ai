/// IM 连接配置
class ImConfig {
  final String wsUrl;
  final Duration heartbeatInterval;
  final int heartbeatTimeout;
  final Duration reconnectBaseDelay;
  final Duration reconnectMaxDelay;

  const ImConfig({
    required this.wsUrl,
    this.heartbeatInterval = const Duration(seconds: 30),
    this.heartbeatTimeout = 3,
    this.reconnectBaseDelay = const Duration(seconds: 1),
    this.reconnectMaxDelay = const Duration(seconds: 30),
  });
}
