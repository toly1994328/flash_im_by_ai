import 'package:flutter/material.dart';
import '../data/message.dart';

enum MenuAction { copy, reply, recall, delete, multiSelect }

class MessageActionMenu {
  static void show({
    required BuildContext context,
    required Offset position,
    required Size bubbleSize,
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
        bubbleSize: bubbleSize,
        actions: actions,
        isMe: isMe,
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

class _MenuOverlay extends StatefulWidget {
  final Offset position;
  final Size bubbleSize;
  final List<MenuAction> actions;
  final bool isMe;
  final void Function(MenuAction) onAction;
  final VoidCallback onDismiss;

  const _MenuOverlay({
    required this.position,
    required this.bubbleSize,
    required this.actions,
    required this.isMe,
    required this.onAction,
    required this.onDismiss,
  });

  @override
  State<_MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<_MenuOverlay>
    with SingleTickerProviderStateMixin {
  static const _arrowSize = 6.0;
  static const _radius = 12.0;
  static const _color = Color(0xFF4C4C4C);

  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const menuPadding = 8.0;

    final bubbleRight = widget.position.dx + widget.bubbleSize.width;
    final bubbleTop = widget.position.dy;
    final bubbleBottom = widget.position.dy + widget.bubbleSize.height;
    final statusBar = MediaQuery.of(context).padding.top;
    final showAbove = bubbleTop - statusBar > 90;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: widget.isMe ? null : widget.position.dx,
          right: widget.isMe ? screenSize.width - bubbleRight : null,
          top: showAbove ? null : bubbleBottom + 4,
          bottom: showAbove ? screenSize.height - bubbleTop + 4 : null,
          child: FadeTransition(
            opacity: _opacity,
            child: _buildMenu(showAbove),
          ),
        ),
      ],
    );
  }

  Widget _buildMenu(bool showAbove) {
    final menuItems = Row(
      mainAxisSize: MainAxisSize.min,
      children: widget.actions.map((action) {
        final (icon, label) = _actionInfo(action);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onAction(action),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(height: 4),
                Text(label,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        );
      }).toList(),
    );

    return Material(
      color: Colors.transparent,
      child: CustomPaint(
      painter: _BubblePainter(
        isMe: widget.isMe,
        showAbove: showAbove,
        bubbleWidth: widget.bubbleSize.width,
        arrowSize: _arrowSize,
        radius: _radius,
        color: _color,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: showAbove ? 10 : 10 + _arrowSize,
          bottom: showAbove ? 10 + _arrowSize : 10,
        ),
        child: menuItems,
        ),
      ),
    );
  }

  static (IconData, String) _actionInfo(MenuAction action) {
    return switch (action) {
      MenuAction.copy => (Icons.copy, '复制'),
      MenuAction.reply => (Icons.format_quote, '引用'),
      MenuAction.recall => (Icons.undo, '撤回'),
      MenuAction.delete => (Icons.delete_outline, '删除'),
      MenuAction.multiSelect => (Icons.checklist, '多选'),
    };
  }
}

/// 自定义绘制带尖角的气泡背景
class _BubblePainter extends CustomPainter {
  final bool isMe;
  final bool showAbove;
  final double bubbleWidth;
  final double arrowSize;
  final double radius;
  final Color color;

  _BubblePainter({
    required this.isMe,
    required this.showAbove,
    required this.bubbleWidth,
    required this.arrowSize,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final r = radius;
    final aH = arrowSize;
    const aW = 9.0;
    const minMargin = 16.0;

    final bubbleCenter = bubbleWidth / 2;
    final rawArrowX = isMe ? w - bubbleCenter : bubbleCenter;
    final arrowX = rawArrowX.clamp(minMargin + aW, w - minMargin - aW);

    final path = Path();

    if (showAbove) {
      final edge = h - aH;

      path.moveTo(r, 0);
      path.lineTo(w - r, 0);
      path.quadraticBezierTo(w, 0, w, r);
      path.lineTo(w, edge - r);
      path.quadraticBezierTo(w, edge, w - r, edge);

      // 四段三次贝塞尔曲线
      final tipY = edge + aH;
      final midY = edge + aH * 0.5;

      path.lineTo(arrowX + aW, edge);
      path.cubicTo(arrowX + aW * 0.58, edge, arrowX + aW * 0.39, midY + aH * -0.25, arrowX + aW * 0.3, midY);
      path.cubicTo(arrowX + aW * 0.13, midY + aH * 0.37, arrowX + 0.9, tipY, arrowX, tipY);
      path.cubicTo(arrowX - 0.9, tipY, arrowX - aW * 0.13, midY + aH * 0.37, arrowX - aW * 0.3, midY);
      path.cubicTo(arrowX - aW * 0.39, midY + aH * -0.25, arrowX - aW * 0.58, edge, arrowX - aW, edge);

      path.lineTo(r, edge);
      path.quadraticBezierTo(0, edge, 0, edge - r);
      path.lineTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0);
    } else {
      final edge = aH;
      final tipY = 0.0;
      final midY = aH * 0.5;

      path.moveTo(r, edge);

      path.lineTo(arrowX - aW, edge);
      path.cubicTo(arrowX - aW * 0.58, edge, arrowX - aW * 0.39, midY - aH * -0.25, arrowX - aW * 0.3, midY);
      path.cubicTo(arrowX - aW * 0.13, midY - aH * 0.37, arrowX - 0.9, tipY, arrowX, tipY);
      path.cubicTo(arrowX + 0.9, tipY, arrowX + aW * 0.13, midY - aH * 0.37, arrowX + aW * 0.3, midY);
      path.cubicTo(arrowX + aW * 0.39, midY - aH * -0.25, arrowX + aW * 0.58, edge, arrowX + aW, edge);

      path.lineTo(w - r, edge);
      path.quadraticBezierTo(w, edge, w, edge + r);
      path.lineTo(w, h - r);
      path.quadraticBezierTo(w, h, w - r, h);
      path.lineTo(r, h);
      path.quadraticBezierTo(0, h, 0, h - r);
      path.lineTo(0, edge + r);
      path.quadraticBezierTo(0, edge, r, edge);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) =>
      isMe != old.isMe || showAbove != old.showAbove || bubbleWidth != old.bubbleWidth;
}
