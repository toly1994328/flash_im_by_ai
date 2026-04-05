import 'package:flash_shared/flash_shared.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
    return Text(
      conversation.lastMessagePreview ?? '',
      style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildUnreadBadge() {
    final count = conversation.unreadCount;
    final text = count > 99 ? '99+' : count.toString();
    final isSingleDigit = text.length < 2;
    final width = isSingleDigit ? 20.0 : (text.length == 2 ? 26.0 : 34.0);

    return Container(
      width: width,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: isSingleDigit ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isSingleDigit ? null : BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
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
