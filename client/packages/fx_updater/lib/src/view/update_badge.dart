import 'package:flutter/material.dart';

import '../data/update_info.dart';
import '../logic/update_manager.dart';

/// 更新小红点组件
///
/// 自动监听 FxUpdater 的 stream，有更新时显示红点，否则隐藏。
/// 只负责渲染红点本身，定位由外部控制。
class FxUpdateBadge extends StatelessWidget {
  final double size;
  final Color color;

  const FxUpdateBadge({
    super.key,
    this.size = 8,
    this.color = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UpdateCheckResult>(
      stream: FxUpdater().stream,
      builder: (BuildContext context, AsyncSnapshot<UpdateCheckResult> snapshot) {
        final bool show = FxUpdater().hasUpdate;
        if (!show) return const SizedBox.shrink();
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
