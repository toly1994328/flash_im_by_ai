class AppConfig {
  static const String host = String.fromEnvironment('SERVER_HOST', defaultValue: '192.168.1.75');
  static const int port = int.fromEnvironment('SERVER_PORT', defaultValue: 9600);
  static const bool enableSMS = bool.fromEnvironment('enableSMS', defaultValue: true);
  static String get baseUrl => 'http://$host:$port';
}
