import 'package:flutter/material.dart';

/// 引用气泡：嵌套在消息气泡内，显示被引用消息的摘要
class ReplyBubble extends StatelessWidget {
  final String senderName;
  final String content;
  final int msgType;

  const ReplyBubble({
    super.key,
    required this.senderName,
    required this.content,
    required this.msgType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(4),
        border: const Border(
          left: BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            senderName,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF3B82F6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatContent(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  String _formatContent() {
    return switch (msgType) {
      1 => '[图片]',
      2 => '[视频]',
      3 => '[文件]',
      _ => content,
    };
  }
}
