/// 极简的、基于 tag 的日志库，支持可插拔的输出代理。
///
/// 特性：
/// - 基于 tag 的模块过滤
/// - release 模式零开销（通过 assert 实现）
/// - 可插拔代理，方便替换为文件/远程/第三方日志实现
/// - 终端 ANSI 彩色输出
///
/// 快速使用：
/// ```dart
/// final log = FxLog('SyncEngine');
/// log.d('已连接');
/// log.w('重试中', error: e);
/// log.e('连接失败', error: e, stackTrace: st);
/// ```
///
/// 替换实现：
/// ```dart
/// FxLog.delegate = MyCustomLogDelegate();
/// ```
library;

export 'src/log.dart';
export 'src/log_delegate.dart';
export 'src/log_level.dart';
export 'src/debug_log_delegate.dart';
