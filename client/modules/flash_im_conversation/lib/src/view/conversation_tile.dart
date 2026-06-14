import 'package:flash_shared/flash_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/conversation.dart';

/// 会话列表项组件
///
/// 参考微信风格：左侧头像 + 右侧名称/时间/预览
class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback? onTap;
  final bool isOnline;
  final bool isActive;
  final String? currentUserId;

  const ConversationTile({
    super.key,
    required this.conversation,
    this.onTap,
    this.isOnline = false,
    this.isActive = false,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      // onDoubleTap: kDebugMode ? () => _showDebugInfo(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8F0FE) : Colors.white,
          border: const Border(
            bottom: BorderSide(color: Color(0x11000000), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTitleRow(),
                  const SizedBox(height: 4),
                  _buildSubtitleRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildAvatarImage(),
        if (conversation.unreadCount > 0)
          Positioned(
            top: -6,
            right: -6,
            child: _buildUnreadBadge(),
          ),
        if (!conversation.isGroup && isOnline)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF07C160),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarImage() {
    if (conversation.isSkeleton) {
      return Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }
    if (conversation.isGroup) {
      final avatar = conversation.displayAvatar;
      if (avatar != null && avatar.startsWith('grid:')) {
        return _buildGridAvatar(avatar);
      }
      if (avatar != null && avatar.isNotEmpty) {
        return AvatarWidget(avatar: avatar, size: 44, borderRadius: 6);
      }
      return Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.group, color: Colors.white, size: 24),
      );
    }
    return AvatarWidget(
      avatar: conversation.peerAvatar,
      size: 44,
      borderRadius: 6,
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        Expanded(
          child: conversation.isSkeleton
            ? Container(height: 14, width: 80, decoration: BoxDecoration(
                color: Colors.grey[200], borderRadius: BorderRadius.circular(4)))
            : Text(
                conversation.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        ),
        if (conversation.lastMessageAt != null)
          Text(
            _formatTime(conversation.lastMessageAt!),
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
      ],
    );
  }

  Widget _buildSubtitleRow() {
    final mentions = conversation.mentionMeRecords;
    final mentionCount = mentions.length;
    if (mentionCount > 0 && conversation.unreadCount > 0) {
      final hasMe = mentions.any((m) => m.type == MentionType.me);
      final label = hasMe ? '有人@我' : '@所有人';
      final text = mentionCount > 1 ? '[$label×$mentionCount] ' : '[$label] ';
      return Row(
        children: [
          Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFFFF4D4F), fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              conversation.lastMessagePreview ?? '',
              style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    return Text(
      conversation.lastMessagePreview ?? '',
      style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildUnreadBadge() {
    return UnreadBadge(count: conversation.unreadCount, size: BadgeSize.medium);
  }

  Widget _buildGridAvatar(String gridStr) {
    final avatarList = gridStr.substring(5).split(',');
    final members = <GroupAvatarMember>[];
    for (var i = 0; i < avatarList.length; i++) {
      final a = avatarList[i].trim();
      members.add(GroupAvatarMember(
        id: 'member_$i',
        avatarUrl: a.isNotEmpty ? a : null,
      ));
    }
    return GroupAvatarWidget(members: members, size: 44, borderRadius: 6);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(time.year, time.month, time.day);

    if (messageDay == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDay == yesterday) {
      return '昨天';
    } else if (today.difference(messageDay).inDays < 7) {
      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[time.weekday - 1];
    } else {
      return '${time.month}/${time.day}';
    }
  }
}
