import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 拖拽移动窗口区域（不含双击全屏）
class DragMoveArea extends StatelessWidget {
  const DragMoveArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => windowManager.startDragging(),
      child: child,
    );
  }
}
