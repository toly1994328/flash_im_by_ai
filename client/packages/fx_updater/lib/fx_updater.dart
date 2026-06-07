/// 通用应用更新框架
///
/// 提供版本检测、策略接口、通用弹窗。
/// 使用方通过回调注入数据获取逻辑，框架不依赖任何网络库。
library;

// data
export 'src/data/app_version.dart';
export 'src/data/update_info.dart';

// logic
export 'src/logic/update_checker.dart';
export 'src/logic/update_manager.dart';
export 'src/logic/update_strategy.dart';

// view
export 'src/view/update_dialog.dart';
export 'src/view/update_badge.dart';
