import 'package:flutter/material.dart';
import '../data/message.dart';

enum MenuAction { copy, reply, recall, delete, multiSelect }

class MessageActionMenu {
  static void show({
    required BuildContext context,
    required Offset position,
    required Message message,
    required bool isMe,
    required void Function(MenuAction action) onAction,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    final actions = _getActions(message, isMe);
    if (actions.isEmpty) return;

    entry = OverlayEntry(
      builder: (ctx) => _MenuOverlay(
        position: position,
        actions: actions,
        onAction: (action) {
          entry.remove();
          onAction(action);
        },
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  static List<MenuAction> _getActions(Message message, bool isMe) {
    if (message.isSystem || message.isRecalled) return [];
    return [
      if (message.isText) MenuAction.copy,
      MenuAction.reply,
      if (isMe && _isWithinRecallWindow(message)) MenuAction.recall,
      MenuAction.delete,
      MenuAction.multiSelect,
    ];
  }

  static bool _isWithinRecallWindow(Message message) {
    return DateTime.now().difference(message.createdAt).inSeconds <= 120;
  }
}

class _MenuOverlay extends StatelessWidget {
  final Offset position;
  final List<MenuAction> actions;
  final void Function(MenuAction) onAction;
  final VoidCallback onDismiss;

  const _MenuOverlay({
    required this.position,
    required this.actions,
    required this.onAction,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const menuHeight = 48.0;
    const menuPadding = 8.0;

    // 菜单宽度根据项数计算
    final menuWidth = actions.length * 60.0 + 16;

    // 水平居中于点击位置，但不超出屏幕
    var left = position.dx - menuWidth / 2;
    if (left < menuPadding) left = menuPadding;
    if (left + menuWidth > screenSize.width - menuPadding) {
      left = screenSize.width - menuWidth - menuPadding;
    }

    // 默认显示在上方，空间不够则下方
    var top = position.dy - menuHeight - 12;
    if (top < MediaQuery.of(context).padding.top + menuPadding) {
      top = position.dy + 12;
    }

    return Stack(
      children: [
        // 遮罩
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        // 菜单
        Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4C4C4C),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: actions.map((action) {
                  final (icon, label) = _actionInfo(action);
                  return GestureDetector(
                    onTap: () => onAction(action),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(height: 2),
                          Text(label,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static (IconData, String) _actionInfo(MenuAction action) {
    return switch (action) {
      MenuAction.copy => (Icons.copy, '复制'),
      MenuAction.reply => (Icons.reply, '引用'),
      MenuAction.recall => (Icons.undo, '撤回'),
      MenuAction.delete => (Icons.delete_outline, '删除'),
      MenuAction.multiSelect => (Icons.check_box_outlined, '多选'),
    };
  }
}
