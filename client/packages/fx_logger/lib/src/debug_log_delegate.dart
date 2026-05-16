import 'package:flutter/foundation.dart';

import 'log_delegate.dart';
import 'log_level.dart';

/// 默认的 [LogDelegate] 实现。
///
/// - 使用 [debugPrint]（自带节流，不会丢帧）。
/// - 仅在 debug 模式下输出（通过 assert），release 模式零开销。
/// - 支持终端 ANSI 彩色输出。
class DebugLogDelegate implements LogDelegate {
  /// 最低输出级别，低于此级别的日志会被忽略。
  final LogLevel minLevel;

  /// 是否使用 ANSI 颜色码。
  final bool useColor;

  const DebugLogDelegate({
    this.minLevel = LogLevel.debug,
    this.useColor = true,
  });

  static const _levelLabels = {
    LogLevel.debug: 'D',
    LogLevel.info: 'I',
    LogLevel.warning: 'W',
    LogLevel.error: 'E',
  };

  static const _levelColors = {
    LogLevel.debug: '\x1B[0m', // 默认色
    LogLevel.info: '\x1B[38;5;12m', // 蓝色
    LogLevel.warning: '\x1B[38;5;208m', // 橙色
    LogLevel.error: '\x1B[38;5;196m', // 红色
  };

  static const _reset = '\x1B[0m';

  @override
  void log(
    String tag,
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // 整个赋值逻辑包裹在 assert 中，release 模式下编译器会完全移除此代码块。
    assert(() {
      if (level.index < minLevel.index) return true;

      final label = _levelLabels[level] ?? '?';
      final buffer = StringBuffer();

      if (useColor) buffer.write(_levelColors[level] ?? '');
      buffer.write('[$label/$tag] $message');
      if (error != null) buffer.write(' | $error');
      if (useColor) buffer.write(_reset);

      debugPrint(buffer.toString());

      if (stackTrace != null && level.index >= LogLevel.error.index) {
        debugPrint(stackTrace.toString());
      }

      return true;
    }());
  }
}
