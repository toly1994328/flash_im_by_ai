import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fx_env/fx_env.dart';
import 'package:tolyui_feedback/tolyui_feedback.dart' hide showTolyPopPicker;
import 'package:tolyui_feedback_modal/tolyui_feedback_modal.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/conversation.dart';
import '../data/conversation_menu_action.dart';
import 'conversation_context_menu.dart';
import 'conversation_delete_dialog.dart';

/// 会话列表项组件
///
/// 参考微信风格：左侧头像 + 右侧名称/时间/预览
/// 移动端：左滑暴露操作按钮 (Slidable)
/// 桌面端：右键弹出菜单 (TolyPopover)
/// 移动端长按：BottomSheet 全量菜单
class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback? onTap;
  final bool isOnline;
  final bool isActive;
  final String? currentUserId;

  // ─── 操作回调 ───
  final Future<void> Function(String conversationId)? onTogglePin;
  final Future<void> Function(String conversationId)? onToggleMute;
  final Future<void> Function(String conversationId)? onMarkRead;
  final Future<void> Function(String conversationId)? onMarkUnread;
  final Future<void> Function(String conversationId)? onDelete;
  final Future<void> Function(String conversationId)? onClearAll;

  const ConversationTile({
    super.key,
    required this.conversation,
    this.onTap,
    this.isOnline = false,
    this.isActive = false,
    this.currentUserId,
    this.onTogglePin,
    this.onToggleMute,
    this.onMarkRead,
    this.onMarkUnread,
    this.onDelete,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final tile = _buildTile(context);

    if (kApp.isDesktop) {
      return _buildDesktopTile(context, tile);
    }
    return _buildMobileTile(tile);
  }

  // ─── 移动端：Slidable ───

  Widget _buildMobileTile(Widget tile) {
    final actions = getConversationActions(
      conv: conversation,
      isSlidableView: true,
    );

    return Builder(
      builder: (context) => Slidable(
        key: ValueKey('slide_${conversation.id}'),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          children: actions
              .map((action) => _buildSlideActionButton(context, action))
              .toList(),
        ),
        child: GestureDetector(
          onLongPressStart: (_) => _showMobileMenu(context),
          child: tile,
        ),
      ),
    );
  }

  Widget _buildSlideActionButton(
    BuildContext context,
    ConversationMenuAction action,
  ) {
    final (icon, _) = actionInfo(action, conversation);
    final color = slideActionColor(action);

    return GestureDetector(
      onTap: () => _handleAction(context, action),
      child: Container(
        width: 64,
        color: color,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              _slideLabel(action),
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _slideLabel(ConversationMenuAction action) {
    return switch (action) {
      ConversationMenuAction.pin => '置顶',
      ConversationMenuAction.mute => '免打扰',
      ConversationMenuAction.markRead => '已读',
      ConversationMenuAction.delete => '删除',
      _ => '',
    };
  }

  // ─── 桌面端：TolyPopover ───

  Widget _buildDesktopTile(BuildContext context, Widget tile) {
    return TolyPopover(
      placement: Placement.bottomStart,
      maxWidth: 180,
      decorationConfig: const DecorationConfig(
        backgroundColor: Colors.white,
        radius: Radius.circular(8),
        isBubble: false,
      ),
      gap: 4,
      overlayBuilder: (context, ctrl) => ConversationContextMenu(
        conversation: conversation,
        onAction: (action) {
          ctrl.close();
          _handleAction(context, action);
        },
      ),
      builder: (context, ctrl, child) => GestureDetector(
        onSecondaryTapUp: (details) => ctrl.open(position: details.localPosition),
        child: child,
      ),
      child: tile,
    );
  }

  // ─── 移动端长按菜单 ───

  void _showMobileMenu(BuildContext context) {
    final actions = getConversationActions(
      conv: conversation,
      isSlidableView: false,
    );

    showTolyPopPicker<void>(
      context: context,
      title: Text(conversation.displayName),
      tasks: actions.map((action) {
        final (icon, label) = actionInfo(action, conversation);
        final isDelete = action == ConversationMenuAction.delete;
        return TolyMenuItem(
          info: label,
          content: Row(
            children: [
              Icon(icon, color: isDelete ? const Color(0xFFFF4D4F) : null, size: 22),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isDelete ? const Color(0xFFFF4D4F) : null,
                ),
              ),
            ],
          ),
          task: () {
            _handleAction(context, action);
            return null;
          },
        );
      }).toList(),
    );
  }

  // ─── 操作分发 ───

  void _handleAction(BuildContext context, ConversationMenuAction action) {
    final id = conversation.id;
    switch (action) {
      case ConversationMenuAction.pin:
        onTogglePin?.call(id);
      case ConversationMenuAction.mute:
        onToggleMute?.call(id);
      case ConversationMenuAction.markRead:
        onMarkRead?.call(id);
      case ConversationMenuAction.markUnread:
        onMarkUnread?.call(id);
      case ConversationMenuAction.delete:
        _confirmDelete(context, id);
      case ConversationMenuAction.clearAll:
        _confirmClearAll(context, id);
    }
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await ConversationDeleteDialog.showDeleteConfirm(
      context,
      name: conversation.displayName,
    );
    if (confirmed) {
      onDelete?.call(id);
    }
  }

  Future<void> _confirmClearAll(BuildContext context, String id) async {
    final confirmed = await ConversationDeleteDialog.showClearAllConfirm(context, name: conversation.displayName);
    if (confirmed) {
      onClearAll?.call(id);
    }
  }

  // ─── 原有 UI ───

  Widget _buildTile(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
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
        if (conversation.isMuted)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.volume_off, size: 14, color: Colors.grey[400]),
          ),
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
