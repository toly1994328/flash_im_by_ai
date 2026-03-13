/// Playground 全局配置
class PlaygroundConfig {
  static String host = '192.168.1.75';
  static int port = 9600;

  static String get baseUrl => 'http://$host:$port';
}
