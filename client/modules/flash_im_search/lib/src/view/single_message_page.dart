import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/search_models.dart';
import 'widgets/highlight_text.dart';

/// 单条消息详情页
///
/// 从会话内搜索点击某条消息后展示，显示完整的消息信息。
class SingleMessagePage extends StatelessWidget {
  final MessageSearchItem message;
  final String keyword;

  const SingleMessagePage({
    super.key,
    required this.message,
    required this.keyword,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '消息详情',
          style: TextStyle(fontSize: 17, color: Color(0xFF333333)),
        ),
        leading: const BackButton(color: Color(0xFF333333)),
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 10),
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 发送者信息
            Row(
              children: [
                AvatarWidget(avatar: message.senderAvatar, size: 44, borderRadius: 6),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.senderName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.createdAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
                if (message.seq != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#${message.seq}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFE8E8E8)),
            const SizedBox(height: 16),
            // 消息内容（高亮关键词）
            HighlightText(
              text: message.content,
              keyword: keyword,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF333333),
                height: 1.6,
              ),
              highlightStyle: const TextStyle(
                fontSize: 15,
                color: Color(0xFF3B82F6),
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.year}/${time.month.toString().padLeft(2, '0')}/${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
