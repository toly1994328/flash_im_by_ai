import 'package:flash_session/flash_session.dart';
import 'package:flutter/material.dart';
import '../data/conversation.dart';

/// 会话列表项组件
///
/// 参考微信风格：左侧头像 + 右侧名称/时间/预览
class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback? onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
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
    final peerId = conversation.peerUserId;
    if (conversation.type == 0 && peerId != null) {
      // 单聊：用对方信息构建临时 User 给 UserAvatar
      final tempUser = User(
        userId: int.tryParse(peerId) ?? 0,
        phone: '',
        nickname: conversation.peerNickname ?? '',
        avatar: conversation.peerAvatar ?? '',
        signature: '',
      );
      return UserAvatar(user: tempUser, size: 48, borderRadius: 6);
    }
    // 群聊或无对方信息：占位头像
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.group, color: Colors.white, size: 28),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
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
    return Row(
      children: [
        Expanded(
          child: Text(
            conversation.lastMessagePreview ?? '',
            style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (conversation.unreadCount > 0) _buildUnreadBadge(),
      ],
    );
  }

  Widget _buildUnreadBadge() {
    final count = conversation.unreadCount;
    final text = count > 99 ? '99+' : count.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[time.weekday - 1];
    } else {
      return '${time.month}/${time.day}';
    }
  }
}
