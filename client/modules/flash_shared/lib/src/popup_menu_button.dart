import 'package:flutter/material.dart';

/// 弹出菜单�?
class WxMenuItem {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const WxMenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });
}

/// 微信风格右上角弹出菜单按�?
///
/// 点击后在按钮下方弹出带尖角的气泡菜单，支持动画�?
class WxPopupMenuButton extends StatefulWidget {
  final Widget child;
  final List<WxMenuItem> items;

  const WxPopupMenuButton({
    super.key,
    required this.child,
    required this.items,
  });

  @override
  State<WxPopupMenuButton> createState() => _WxPopupMenuButtonState();
}

class _WxPopupMenuButtonState extends State<WxPopupMenuButton>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlay;
  final GlobalKey _buttonKey = GlobalKey();
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  void _show() {
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlay = OverlayEntry(
      builder: (context) {
        const arrowSize = 8.0;
        const rightEdge = 6.0;
        return Stack(
          children: [
            GestureDetector(
              onTap: _hide,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
            Positioned(
              top: offset.dy + size.height + 4,
              right: rightEdge,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  alignment: Alignment.topRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 尖角
                      const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: CustomPaint(
                          size: Size(arrowSize * 2, arrowSize),
                          painter: _ArrowPainter(),
                        ),
                      ),
                      // 气泡
                      Material(
                        color: const Color(0xFF4C4C4C),
                        borderRadius: BorderRadius.circular(8),
                        elevation: 8,
                        shadowColor: Colors.black.withValues(alpha: 0.2),
                        child: IntrinsicWidth(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < widget.items.length; i++) ...[
                                if (i > 0)
                                  Container(
                                    height: 0.5,
                                    color: const Color(0xFF5C5C5C),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                  ),
                                _buildItem(widget.items[i]),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_overlay!);
    _animController.forward();
  }

  Future<void> _hide() async {
    await _animController.reverse();
    _overlay?.remove();
    _overlay = null;
  }

  Widget _buildItem(WxMenuItem item) {
    return GestureDetector(
      onTap: () {
        _hide();
        item.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              item.text,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _buttonKey,
      onTap: _show,
      child: widget.child,
    );
  }
}

/// 深色尖角画笔
class _ArrowPainter extends CustomPainter {
  const _ArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF4C4C4C);
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
