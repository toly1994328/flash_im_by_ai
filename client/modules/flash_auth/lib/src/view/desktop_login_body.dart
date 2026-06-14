import 'package:flutter/material.dart';
import 'package:fx_env/fx_env.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/auth_repository.dart';
import '../logic/login/login_mixin.dart';
import 'components/login_segment_tab.dart';
import 'components/agreement_row.dart';
import 'components/action_button.dart';
import 'components/qr_login_form.dart';
import 'login_page.dart';

/// 桌面端登录布局：左侧品牌区 + 右侧表单卡片（右上角折角切换扫码）
class DesktopLoginBody extends StatefulWidget {
  final LoginTab tab;
  final ValueChanged<LoginTab> onTabChanged;
  final bool enableSMS;
  final bool isScanTab;
  final bool agreed;
  final VoidCallback onToggleAgreed;
  final String baseUrl;
  final bool canLogin;
  final bool isLoading;
  final VoidCallback onLogin;
  final Widget formWidget;
  final AuthRepository authRepository;
  final OnLoginSuccess onLoginSuccess;

  const DesktopLoginBody({
    super.key,
    required this.tab,
    required this.onTabChanged,
    required this.enableSMS,
    required this.isScanTab,
    required this.agreed,
    required this.onToggleAgreed,
    required this.baseUrl,
    required this.canLogin,
    required this.isLoading,
    required this.onLogin,
    required this.formWidget,
    required this.authRepository,
    required this.onLoginSuccess,
  });

  @override
  State<DesktopLoginBody> createState() => _DesktopLoginBodyState();
}

class _DesktopLoginBodyState extends State<DesktopLoginBody>
    with SingleTickerProviderStateMixin {
  bool _showQr = false;
  bool _animating = false;
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        setState(() => _animating = false);
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _showQr = !_showQr;
      _animating = true;
    });
    if (_showQr) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DragMoveArea(
      child: Row(children: [_buildBrandPanel(), _buildFormPanel()]),
    );
  }

  Widget _buildBrandPanel() {
    return SizedBox(
      width: 240,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              top: 120,
              right: 30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset('assets/images/logo.png'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'FLASH IM',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '连接此刻，不止于此',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPanel() {
    return Expanded(
      child: Column(
        children: [
          if (kApp.isWindows) Container(
            height: 36,
            color: const Color(0xFFF8FAFC),
            child: const Row(children: [Spacer(), WindowsButtons()]),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 40,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      constraints: BoxConstraints(
                        maxWidth: _showQr ? 360 : 460,
                      ),
                      clipBehavior: Clip.hardEdge,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 56,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: _showQr
                            ? _buildQrContent()
                            : _buildFormContent(),
                      ),
                    ),
                    // 右上角折角切换
                    Positioned(
                      top: -2,
                      right: -2,
                      child: _CornerToggle(showQr: _showQr, onTap: _toggle),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      children: [
        LoginSegmentTab(
          current: widget.tab,
          onChanged: widget.onTabChanged,
          enableSMS: widget.enableSMS,
          isDesktop: true,
          compact: _animating,
        ),
        const SizedBox(height: 24),
        widget.formWidget,
        const SizedBox(height: 36),
        AgreementRow(
          checked: widget.agreed,
          onTap: widget.onToggleAgreed,
          baseUrl: widget.baseUrl,
        ),
        const SizedBox(height: 32),
        ActionButton(
          enabled: widget.canLogin || widget.isLoading,
          loading: widget.isLoading,
          onPressed: widget.onLogin,
        ),
      ],
    );
  }

  Widget _buildQrContent() {
    return Column(
      key: const ValueKey('qr'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        const Text(
          '扫码登录',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        QrLoginForm(
          authRepository: widget.authRepository,
          onLoginSuccess: widget.onLoginSuccess,
        ),
      ],
    );
  }
}

/// 右上角折角切换按钮 — 三角折角 + 图标
class _CornerToggle extends StatefulWidget {
  final bool showQr;
  final VoidCallback onTap;

  const _CornerToggle({required this.showQr, required this.onTap});

  @override
  State<_CornerToggle> createState() => _CornerToggleState();
}

class _CornerToggleState extends State<_CornerToggle> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(
            painter: _CornerPainter(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.8),
            ),
            child: Align(
              alignment: const Alignment(0.55, -0.55),
              child: Icon(
                widget.showQr ? Icons.keyboard_outlined : Icons.qr_code_2,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;

  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final r = 16.0;

    // 主体三角 + 两条边各延伸20px直线
    final s = 6.0;
    final ext = 32.0;
    final strokeWidth = 3.0;

    // 画三角形（斜边用曲线，只保留右上角圆弧）
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r))
      ..lineTo(size.width, size.height)
      // 斜边用贝塞尔曲线（向内凹）
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.35, 0, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);

    // 上边向左延伸的水平线（从三角形左上角沿卡片顶部）
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s, 1.5), Offset(-ext, 1.5), linePaint);

    // 右边向下延伸的竖直线（从三角形右下角沿卡片右侧）
    canvas.drawLine(
      Offset(size.width - 1.5, size.height - s),
      Offset(size.width - 1.5, size.height + ext),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}
