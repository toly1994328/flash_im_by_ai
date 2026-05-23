class AppConfig {
  static String host = '192.168.1.75';
  // static String host = '82.157.176.209';
  
  static int port = 9600;
  static String get baseUrl => 'http://$host:$port';
}
