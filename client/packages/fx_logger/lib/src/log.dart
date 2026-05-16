import 'debug_log_delegate.dart';
import 'log_delegate.dart';
import 'log_level.dart';

/// 基于 tag 的日志实例（工厂缓存模式）。
///
/// 同名的 FxLog 全局只有一个实例，随用随取：
/// ```dart
/// final log = FxLog('SyncEngine');
/// log.d('开始同步...');
/// log.w('重试中', error: e);
/// log.e('连接失败', error: e, stackTrace: st);
/// ```
///
/// 在不同文件中使用同一个 tag，拿到的是同一个对象：
/// ```dart
/// // file_a.dart
/// final log = FxLog('Chat');
/// // file_b.dart
/// final log = FxLog('Chat');
/// // identical(file_a.log, file_b.log) == true
/// ```
///
/// 替换全局代理以改变输出行为：
/// ```dart
/// FxLog.delegate = MyRemoteLogDelegate();
/// ```
class FxLog {
  /// 全局日志代理。所有 [FxLog] 实例的输出都经过它。
  ///
  /// 默认为 [DebugLogDelegate]（debugPrint + assert 守卫）。
  /// 替换为自定义实现即可对接文件/远程/第三方日志服务。
  static LogDelegate delegate = const DebugLogDelegate();

  /// 工厂缓存：同名返回同一实例。
  static final Map<String, FxLog> _cache = {};

  /// 标识此 logger 来源的 tag（模块名、类名、功能名）。
  final String tag;

  /// 获取或创建一个 [FxLog] 实例。同名共享同一对象。
  factory FxLog(String tag) => _cache.putIfAbsent(tag, () => FxLog._(tag));

  FxLog._(this.tag);

  /// 输出 [LogLevel.debug] 级别日志。
  void d(String message, {Object? error, StackTrace? stackTrace}) {
    delegate.log(tag, LogLevel.debug, message, error: error, stackTrace: stackTrace);
  }

  /// 输出 [LogLevel.info] 级别日志。
  void i(String message, {Object? error, StackTrace? stackTrace}) {
    delegate.log(tag, LogLevel.info, message, error: error, stackTrace: stackTrace);
  }

  /// 输出 [LogLevel.warning] 级别日志。
  void w(String message, {Object? error, StackTrace? stackTrace}) {
    delegate.log(tag, LogLevel.warning, message, error: error, stackTrace: stackTrace);
  }

  /// 输出 [LogLevel.error] 级别日志。
  void e(String message, {Object? error, StackTrace? stackTrace}) {
    delegate.log(tag, LogLevel.error, message, error: error, stackTrace: stackTrace);
  }
}
