import 'package:flutter/material.dart';

/// 关键词高亮文本组件
///
/// 将 [text] 中匹配 [keyword] 的部分用蓝色高亮显示。
/// 匹配不区分大小写。
class HighlightText extends StatelessWidget {
  final String text;
  final String keyword;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int? maxLines;
  final TextOverflow overflow;

  const HighlightText({
    super.key,
    required this.text,
    required this.keyword,
    this.style,
    this.highlightStyle,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ??
        const TextStyle(fontSize: 14, color: Color(0xFF333333));
    final defaultHighlight = highlightStyle ??
        defaultStyle.copyWith(color: const Color(0xFF3B82F6));

    if (keyword.isEmpty) {
      return Text(
        text,
        style: defaultStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    int start = 0;

    while (start < text.length) {
      final index = lowerText.indexOf(lowerKeyword, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: defaultStyle));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: defaultStyle,
        ));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + keyword.length),
        style: defaultHighlight,
      ));
      start = index + keyword.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
