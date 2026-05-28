import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/auth_repository.dart';
import '../logic/login/login_mixin.dart';
import 'components/login_segment_tab.dart';
import 'components/agreement_row.dart';
import 'components/action_button.dart';
import 'components/qr_login_form.dart';
import 'login_page.dart';

/// 桌面端登录布局：左侧品牌区 + 右侧表单卡片
class DesktopLoginBody extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return DragMoveArea(
      child: Row(
        children: [
          // 左侧品牌区
          SizedBox(
            width: 320,
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
          ),
          // 右侧表单区
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 36,
                  color: const Color(0xFFF8FAFC),
                  child: const Row(
                    children: [Spacer(), WindowsButtons()],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 60),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 560),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LoginSegmentTab(current: tab, onChanged: onTabChanged, enableSMS: enableSMS, isDesktop: true),
                            const SizedBox(height: 24),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              alignment: Alignment.topCenter,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  formWidget,
                                  if (!isScanTab) ...[
                                    const SizedBox(height: 36),
                                    AgreementRow(
                                      checked: agreed,
                                      onTap: onToggleAgreed,
                                      baseUrl: baseUrl,
                                    ),
                                    const SizedBox(height: 32),
                                    ActionButton(
                                      enabled: canLogin || isLoading,
                                      loading: isLoading,
                                      onPressed: onLogin,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
