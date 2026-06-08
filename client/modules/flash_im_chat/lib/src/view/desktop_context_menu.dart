import 'package:flutter/material.dart';

import '../data/message.dart';
import 'message_action_menu.dart';

/// 桌面端右键操作菜单（白底竖向列表）
class DesktopContextMenu extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isGroup;
  final bool isPinned;
  final void Function(MenuAction action) onAction;

  const DesktopContextMenu({
    super.key,
    required this.message,
    required this.isMe,
    this.isGroup = false,
    this.isPinned = false,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final List<MenuAction> actions = MessageActionMenu.getActions(
      message,
      isMe,
      isGroup: isGroup,
      isPinned: isPinned,
    );
    if (actions.isEmpty) return const SizedBox.shrink();

    return IntrinsicWidth(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < actions.length; i++)
              _buildItem(actions[i]),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(MenuAction action) {
    final (IconData icon, String label) = _actionInfo(action);
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
              Icon(icon, size: 15, color: const Color(0xFF666666)),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static (IconData, String) _actionInfo(MenuAction action) {
    return switch (action) {
      MenuAction.copy => (Icons.copy, '复制'),
      MenuAction.reply => (Icons.format_quote, '引用'),
      MenuAction.recall => (Icons.undo, '撤回'),
      MenuAction.forward => (Icons.shortcut, '转发'),
      MenuAction.delete => (Icons.delete_outline, '删除'),
      MenuAction.multiSelect => (Icons.checklist, '多选'),
      MenuAction.pin => (Icons.push_pin, '置顶'),
      MenuAction.unpin => (Icons.push_pin_outlined, '取消置顶'),
    };
  }
}
