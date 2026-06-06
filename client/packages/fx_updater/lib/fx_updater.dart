/// 通用应用更新框架
///
/// 提供版本检测、策略接口、通用弹窗。
/// 使用方通过回调注入数据获取逻辑，框架不依赖任何网络库。
library;

export 'src/app_version.dart';
export 'src/update_info.dart';
export 'src/update_checker.dart';
export 'src/update_strategy.dart';
export 'src/update_dialog.dart';
