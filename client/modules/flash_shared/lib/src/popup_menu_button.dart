import 'package:flutter/material.dart';
import 'package:fx_env/fx_env.dart';

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
        final screenWidth = MediaQuery.of(context).size.width;

        if (kApp.isDesktop) {
          // 桌面端：白色卡片 + 白色尖角，居中对齐按钮
          const arrowSize = 6.0;
          // 按钮中心 x 坐标
          final buttonCenterX = offset.dx + size.width / 2;
          return Stack(
            children: [
              GestureDetector(
                onTap: _hide,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
              Positioned(
                top: offset.dy + size.height + 4,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: UnconstrainedBox(
                      child: Transform.translate(
                        offset: Offset(buttonCenterX - screenWidth / 2, 0),
                        child: Column(
                          children: [
                            const CustomPaint(
                              size: Size(arrowSize * 2, arrowSize),
                              painter: _ArrowPainter(color: Colors.white),
                            ),
                            Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              elevation: 12,
                              shadowColor: Colors.black.withValues(alpha: 0.15),
                              child: IntrinsicWidth(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (var i = 0; i < widget.items.length; i++) ...[
                                        if (i > 0)
                                          Container(
                                            height: 0.5,
                                            color: const Color(0xFFF0F0F0),
                                            margin: const EdgeInsets.symmetric(horizontal: 12),
                                          ),
                                        _buildItem(widget.items[i], desktop: true),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }

        // 移动端：深色气泡 + 尖角
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
                      const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: CustomPaint(
                          size: Size(arrowSize * 2, arrowSize),
                          painter: _ArrowPainter(),
                        ),
                      ),
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
                                    margin: const EdgeInsets.symmetric(horizontal: 12),
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

  Widget _buildItem(WxMenuItem item, {bool desktop = false}) {
    final iconColor = desktop ? const Color(0xFF333333) : Colors.white;
    final textColor = desktop ? const Color(0xFF333333) : Colors.white;
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
            Icon(item.icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Text(
              item.text,
              style: TextStyle(fontSize: 14, color: textColor),
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

/// 尖角画笔（支持自定义颜色）
class _ArrowPainter extends CustomPainter {
  final Color color;
  const _ArrowPainter({this.color = const Color(0xFF4C4C4C)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) => oldDelegate.color != color;
}
