import 'package:flutter/widgets.dart';
import 'package:tolyui_mediax_core/tolyui_mediax_core.dart';

/// 图片预览与缓存 Widget 抽象接口
abstract class FxMediaImage {
  /// 全屏预览（多图滑动 + Hero 动画）
  void preview(
    BuildContext context, {
    required List<ImageMeta> items,
    int initialIndex = 0,
    VoidCallback? onDismiss,
  });

  /// 带缓存回调的图片 Widget
  Widget cached({
    required String url,
    String? id,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Map<String, String>? headers,
    void Function(String localPath)? onCached,
  });
}
