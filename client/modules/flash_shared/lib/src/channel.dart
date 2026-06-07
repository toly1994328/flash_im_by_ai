/// 构建渠道标识
///
/// 通过 --dart-define=CHANNEL=standard/google 在编译时注入
class AppChannel {
  static const String _channel =
      String.fromEnvironment('CHANNEL', defaultValue: 'standard');

  /// 是否是 Google Play 渠道
  static bool get isGoogle => _channel == 'google';

  /// 是否是标准渠道（自有分发）
  static bool get isStandard => _channel == 'standard';

  /// 当前渠道名
  static String get name => _channel;
}
