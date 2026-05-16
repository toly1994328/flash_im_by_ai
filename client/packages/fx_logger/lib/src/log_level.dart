/// 日志级别，从低到高排列。
enum LogLevel {
  /// 细粒度调试信息。
  debug,

  /// 一般性信息。
  info,

  /// 潜在的问题警告。
  warning,

  /// 错误事件，应用可能仍能继续运行。
  error,
}
