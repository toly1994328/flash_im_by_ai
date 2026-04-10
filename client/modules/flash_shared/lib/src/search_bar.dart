import 'package:flutter/material.dart';
import 'search_input.dart';

/// 通用搜索栏（微信风格，含灰色背景容器）
///
/// 两种模式：
/// - 占位模式（默认）：显示搜索图标 + 提示文字，点击触发 [onTap]
/// - 输入模式：[editable] = true，内嵌 [FlashSearchInput]
class FlashSearchBar extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;
  final bool editable;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double height;
  final Color backgroundColor;

  const FlashSearchBar({
    super.key,
    this.hintText = '搜索',
    this.onTap,
    this.editable = false,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.height = 36,
    this.backgroundColor = const Color(0xFFEDEDED),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: editable
          ? FlashSearchInput(
              controller: controller,
              focusNode: focusNode,
              hintText: hintText,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              height: height,
            )
          : GestureDetector(
              onTap: onTap,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search, size: 18, color: Color(0xFF999999)),
                    const SizedBox(width: 6),
                    Text(hintText, style: const TextStyle(color: Color(0xFF999999), fontSize: 14)),
                  ],
                ),
              ),
            ),
    );
  }
}
