import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/search_models.dart';
import 'widgets/highlight_text.dart';

/// 消息搜索详情页
///
/// 展示某个会话中所有匹配的消息列表。
class MessageDetailPage extends StatelessWidget {
  final MessageSearchGroup group;
  final String keyword;
  final void Function(String conversationId, String? messageId)? onMessageTap;

  const MessageDetailPage({
    super.key,
    required this.group,
    required this.keyword,
    this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          group.conversationName,
          style: const TextStyle(
            fontSize: 17,
            color: Color(0xFF333333),
          ),
        ),
        leading: const BackButton(color: Color(0xFF333333)),
      ),
      body: ListView.separated(
        itemCount: group.messages.length,
        separatorBuilder: (_, __) => const Divider(
          height: 0.5,
          thickness: 0.5,
          color: Color(0xFFE8E8E8),
          indent: 68,
        ),
        itemBuilder: (context, index) {
          final msg = group.messages[index];
          return _MessageTile(
            message: msg,
            keyword: keyword,
            onTap: () => onMessageTap?.call(
              group.conversationId,
              msg.messageId,
            ),
          );
        },
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final MessageSearchItem message;
  final String keyword;
  final VoidCallback? onTap;

  const _MessageTile({
    required this.message,
    required this.keyword,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarWidget(avatar: message.senderAvatar, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          message.senderName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(message.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  HighlightText(
                    text: message.content,
                    keyword: keyword,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                    highlightStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF3B82F6),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);

    if (date == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    if (date == today.subtract(const Duration(days: 1))) {
      return '昨天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    if (time.year == now.year) {
      return '${time.month}/${time.day}';
    }
    return '${time.year}/${time.month}/${time.day}';
  }
}
