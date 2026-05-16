import 'log_level.dart';

/// 日志输出的抽象接口。
///
/// 实现此接口可将日志重定向到文件、远程服务、
/// 或第三方日志库（如 logger 包、Sentry、Crashlytics 等）。
///
/// 示例：
/// ```dart
/// class SentryLogDelegate implements LogDelegate {
///   @override
///   void log(String tag, LogLevel level, String message, {Object? error, StackTrace? stackTrace}) {
///     if (level == LogLevel.error) {
///       Sentry.captureException(error, stackTrace: stackTrace);
///     }
///   }
/// }
/// ```
abstract class LogDelegate {
  /// 当日志消息产生时调用。
  ///
  /// [tag] 标识来源模块（如 'SyncEngine'、'ChatCubit'）。
  /// [level] 表示严重程度。
  /// [message] 是日志内容。
  /// [error] 是可选的错误对象。
  /// [stackTrace] 是可选的堆栈追踪。
  void log(
    String tag,
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });
}
