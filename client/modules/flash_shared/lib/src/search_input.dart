import 'package:flutter/material.dart';

/// 通用搜索输入框（白色圆角 + 搜索图标 + 文字垂直居中）
///
/// 纯输入框组件，不含外层背景和 padding。
/// 可直接放在 AppBar title、body、Dialog 等任意位置。
class FlashSearchInput extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double height;
  final double borderRadius;
  final Color backgroundColor;

  const FlashSearchInput({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = '搜索',
    this.onChanged,
    this.onSubmitted,
    this.height = 36,
    this.borderRadius = 6,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        expands: true,
        maxLines: null,
        minLines: null,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF999999)),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
