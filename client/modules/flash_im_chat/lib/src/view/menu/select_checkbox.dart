import 'package:flutter/material.dart';

/// 多选模式下消息行左侧的动画复选框
class SelectCheckbox extends StatelessWidget {
  final bool visible;
  final bool selected;

  const SelectCheckbox({super.key, required this.visible, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: visible ? 44 : 0,
      child: visible
          ? Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  key: ValueKey(selected),
                  color: selected ? const Color(0xFF3B82F6) : const Color(0xFFCCCCCC),
                  size: 24,
                ),
              ),
            )
          : null,
    );
  }
}
