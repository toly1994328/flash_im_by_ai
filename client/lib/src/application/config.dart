class AppConfig {
  static String host = '192.168.1.26';
  static int port = 9600;
  static String get baseUrl => 'http://$host:$port';
}
