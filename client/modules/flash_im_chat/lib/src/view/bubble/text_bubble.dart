import 'package:flutter/material.dart';
import '../../data/message.dart';

class TextBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const TextBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF3B82F6) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isMe ? 12 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 12),
        ),
      ),
      child: _buildText(),
    );
  }

  Widget _buildText() {
    final mentions = _parseMentions();
    if (mentions.isEmpty) {
      return Text(message.content,
        style: TextStyle(fontSize: 15, color: isMe ? Colors.white : Colors.black87));
    }
    return RichText(text: TextSpan(children: _buildSpans(mentions)));
  }

  List<_MentionSpan> _parseMentions() {
    final extra = message.extra;
    if (extra == null) return [];
    final list = extra['mentions'];
    if (list is! List) return [];
    return list
        .map((m) => _MentionSpan(
              offset: m['offset'] as int? ?? 0,
              length: m['length'] as int? ?? 0,
            ))
        .where((m) => m.offset >= 0 && m.length > 0) // 过滤静默 mention（offset=-1）
        .toList()
      ..sort((a, b) => a.offset.compareTo(b.offset));
  }

  List<TextSpan> _buildSpans(List<_MentionSpan> mentions) {
    final content = message.content;
    final defaultStyle = TextStyle(fontSize: 15, color: isMe ? Colors.white : Colors.black87);
    final mentionStyle = TextStyle(
      fontSize: 15,
      color: isMe ? const Color(0xFFBBDDFF) : const Color(0xFF3B82F6),
      fontWeight: FontWeight.w500,
    );

    final spans = <TextSpan>[];
    int cursor = 0;

    for (final m in mentions) {
      if (m.offset > cursor && m.offset <= content.length) {
        spans.add(TextSpan(text: content.substring(cursor, m.offset), style: defaultStyle));
      }
      final end = (m.offset + m.length).clamp(0, content.length);
      if (m.offset < content.length) {
        spans.add(TextSpan(text: content.substring(m.offset, end), style: mentionStyle));
      }
      cursor = end;
    }
    if (cursor < content.length) {
      spans.add(TextSpan(text: content.substring(cursor), style: defaultStyle));
    }
    return spans;
  }
}

class _MentionSpan {
  final int offset;
  final int length;
  const _MentionSpan({required this.offset, required this.length});
}
