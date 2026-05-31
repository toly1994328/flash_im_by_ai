import 'package:flutter/material.dart';
import 'package:tolyui_rx_layout/tolyui_rx_layout.dart';

/// 自适应页面跳转
///
/// - 移动端布局（Rx.xs / Rx.sm）：正常 Navigator.push 全屏跳转
/// - 桌面端布局（Rx.md 及以上）：弹窗 + 独立 Navigator，页面内跳转不会跳出弹窗
///
/// 判断依据是 `context.rx` 断点级别（跟随窗口宽度），而非平台类型。
///
/// ```dart
/// adaptivePush(context, builder: (_) => SearchPage(...));
/// ```
Future<T?> adaptivePush<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double width = 420,
  double heightRatio = 0.8,
  double maxHeight = 800,
}) {
  if (context.rx.isDesktop) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final dialogHeight = (screenHeight * heightRatio).clamp(0.0, maxHeight);
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: width,
            height: dialogHeight,
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<T>(
                builder: builder,
              ),
            ),
          ),
        ),
      ),
    );
  }

  return Navigator.of(context).push<T>(MaterialPageRoute(builder: builder));
}
