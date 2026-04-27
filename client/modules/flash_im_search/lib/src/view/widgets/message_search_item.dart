import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../../data/search_models.dart';
import 'highlight_text.dart';

/// 消息搜索结果项组件（按会话分组展示）
class MessageSearchItemWidget extends StatelessWidget {
  final MessageSearchGroup group;
  final String keyword;
  final VoidCallback? onTap;

  const MessageSearchItemWidget({
    super.key,
    required this.group,
    required this.keyword,
    this.onTap,
  });

  Widget _buildAvatar() {
    final avatar = group.conversationAvatar;
    if (avatar != null && avatar.startsWith('grid:')) {
      final parts = avatar.substring(5).split(',');
      final members = parts.asMap().entries.map((e) =>
        GroupAvatarMember(
          id: 'member_${e.key}',
          avatarUrl: e.value.trim().isNotEmpty ? e.value.trim() : null,
        ),
      ).toList();
      return GroupAvatarWidget(members: members, size: 40, borderRadius: 6);
    }
    return AvatarWidget(avatar: avatar, size: 40, borderRadius: 6);
  }

  @override
  Widget build(BuildContext context) {
    final latestMessage =
        group.messages.isNotEmpty ? group.messages.first : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.conversationName,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (group.matchCount > 1)
                        Text(
                          '${group.matchCount}条相关聊天记录',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                          ),
                        ),
                    ],
                  ),
                  if (latestMessage != null) ...[
                    const SizedBox(height: 4),
                    HighlightText(
                      text: '${latestMessage.senderName}: ${latestMessage.content}',
                      keyword: keyword,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                      highlightStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF3B82F6),
                      ),
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
