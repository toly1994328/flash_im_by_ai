import 'package:flutter/foundation.dart';

import 'app_version.dart';
import 'update_info.dart';

/// 获取更新信息的回调（由使用方注入）
typedef FetchUpdateInfo = Future<UpdateInfo?> Function();

/// 更新检查器
///
/// 不关心数据从哪来（HTTP/本地/Mock），通过 [fetchUpdateInfo] 回调注入。
/// 只负责版本比较逻辑。
class UpdateChecker {
  final AppVersion currentVersion;
  final FetchUpdateInfo fetchUpdateInfo;

  UpdateChecker({
    required this.currentVersion,
    required this.fetchUpdateInfo,
  });

  /// 执行检查
  Future<UpdateCheckResult> check() async {
    try {
      final info = await fetchUpdateInfo();
      if (info == null) {
        return UpdateCheckFailed('无法获取更新信息');
      }

      final latestVersion = AppVersion.parse(info.version);
      if (latestVersion > currentVersion) {
        return UpdateAvailable(info);
      }

      return UpdateNotNeeded();
    } catch (e) {
      debugPrint('[fx_updater] check error: $e');
      return UpdateCheckFailed(e.toString());
    }
  }
}
