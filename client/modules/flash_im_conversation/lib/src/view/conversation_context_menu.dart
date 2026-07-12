import 'package:flutter/material.dart';
import '../data/conversation.dart';
import '../data/conversation_menu_action.dart';

/// 桌面端右键操作菜单（白底竖向列表，给 TolyPopover 的 overlayBuilder 用）
class ConversationContextMenu extends StatelessWidget {
  final Conversation conversation;
  final void Function(ConversationMenuAction action) onAction;

  const ConversationContextMenu({
    super.key,
    required this.conversation,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final actions = getConversationActions(
      conv: conversation,
      isSlidableView: false,
    );

    if (actions.isEmpty) return const SizedBox.shrink();

    return IntrinsicWidth(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final action in actions) _buildItem(context, action),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, ConversationMenuAction action) {
    final (icon, label) = actionInfo(action, conversation);
    final isDelete = action == ConversationMenuAction.delete;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onAction(action),
        hoverColor: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: isDelete ? const Color(0xFFFF4D4F) : const Color(0xFF666666),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isDelete ? const Color(0xFFFF4D4F) : const Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
