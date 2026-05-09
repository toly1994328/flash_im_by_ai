import 'package:flutter/material.dart';

/// 合并转发消息详情页（只读展示原始消息列表）
class ForwardDetailPage extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> messages;

  const ForwardDetailPage({
    super.key,
    required this.title,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: messages.length,
        itemBuilder: (_, index) {
          final msg = messages[index];
          return _buildMessageItem(msg);
        },
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> msg) {
    final senderName = msg['sender_name'] as String? ?? '?';
    final content = msg['content'] as String? ?? '';
    final msgType = msg['msg_type'] as int? ?? 0;
    final createdAt = msg['created_at'] as int? ?? 0;
    final time = createdAt > 0
        ? DateTime.fromMillisecondsSinceEpoch(createdAt)
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                senderName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
              ),
              const Spacer(),
              if (time != null)
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatContent(content, msgType),
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
          ),
        ],
      ),
    );
  }

  String _formatContent(String content, int msgType) {
    return switch (msgType) {
      1 => '[图片]',
      2 => '[视频]',
      3 => '[文件]',
      _ => content,
    };
  }
}
