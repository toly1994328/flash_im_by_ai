import 'package:flutter/material.dart';
import '../../data/message.dart';

/// 合并转发消息卡片
class ForwardBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onTap;

  const ForwardBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final forwardMessages = _parseForwardMessages();
    final title = message.content;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 6),
            ...forwardMessages.take(3).map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${m['sender_name'] ?? '?'}: ${_previewContent(m)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )),
            if (forwardMessages.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '查看${forwardMessages.length}条聊天记录',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _parseForwardMessages() {
    final extra = message.extra;
    if (extra == null) return [];
    final list = extra['forward_messages'];
    if (list is List) return list.cast<Map<String, dynamic>>();
    return [];
  }

  String _previewContent(Map<String, dynamic> m) {
    final msgType = m['msg_type'] as int? ?? 0;
    return switch (msgType) {
      1 => '[图片]',
      2 => '[视频]',
      3 => '[文件]',
      _ => (m['content'] as String? ?? '').length > 20
          ? '${(m['content'] as String).substring(0, 20)}...'
          : m['content'] as String? ?? '',
    };
  }
}
