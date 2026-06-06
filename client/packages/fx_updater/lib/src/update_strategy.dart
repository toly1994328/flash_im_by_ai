import 'package:url_launcher/url_launcher.dart';

import 'update_info.dart';

/// 更新策略接口
///
/// 定义"点击更新后做什么"。不同平台注入不同实现。
abstract class UpdateStrategy {
  Future<void> execute(UpdateInfo info);
}

/// URL 跳转策略（iOS 跳 App Store / 鸿蒙跳华为市场）
class UrlLaunchStrategy implements UpdateStrategy {
  @override
  Future<void> execute(UpdateInfo info) async {
    final uri = Uri.parse(info.downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// 空策略（Web 端无需处理）
class NoOpStrategy implements UpdateStrategy {
  @override
  Future<void> execute(UpdateInfo info) async {}
}
