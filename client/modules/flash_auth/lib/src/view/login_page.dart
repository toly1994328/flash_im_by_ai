import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fx_env/fx_env.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../data/auth_repository.dart';
import '../data/login_result.dart';
import '../logic/login/login_mixin.dart';
import 'components/sms_login_form.dart';
import 'components/password_login_form.dart';
import 'components/email_login_form.dart';
import 'components/agreement_row.dart';
import 'components/action_button.dart';
import 'components/login_segment_tab.dart';
import 'components/other_login_row.dart';
import 'components/qr_login_form.dart';
import 'desktop_login_body.dart';

/// 登录成功回调 — 由组装层注入，负责写入 session、跳转等
typedef OnLoginSuccess = void Function(LoginResult result);

class LoginPage extends StatefulWidget {
  final AuthRepository authRepository;
  final OnLoginSuccess onLoginSuccess;
  final bool enableSMS;

  const LoginPage({
    super.key,
    required this.authRepository,
    required this.onLoginSuccess,
    this.enableSMS = true,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with LoginMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 768;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: _isDesktop(context) ? _buildDesktopBody() : _buildMobileBody(),
      ),
    );
  }

  Widget _buildDesktopBody() {
    return DesktopLoginBody(
      tab: tab,
      onTabChanged: switchTab,
      enableSMS: widget.enableSMS,
      isScanTab: isScanTab,
      agreed: agreed,
      onToggleAgreed: () => setState(() => agreed = !agreed),
      baseUrl: widget.authRepository.baseUrl,
      canLogin: canLogin,
      isLoading: isLoading,
      onLogin: login,
      formWidget: _buildForm(),
      authRepository: widget.authRepository,
      onLoginSuccess: widget.onLoginSuccess,
    );
  }

  Widget _buildMobileBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 46),
      child: Column(
        children: [
          const SizedBox(height: 80),
          _BrandHeader(
            onDebugDoubleTap: () {
              smsStrategy.phoneCtrl.text = '13800010001';
            },
          ),
          const SizedBox(height: 60),
          LoginSegmentTab(current: tab, onChanged: switchTab, enableSMS: widget.enableSMS, isDesktop: false),
          const SizedBox(height: 16),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildForm(),
                if (!isScanTab) ...[
                  const SizedBox(height: 36),
                  AgreementRow(
                    checked: agreed,
                    onTap: () => setState(() => agreed = !agreed),
                    baseUrl: widget.authRepository.baseUrl,
                  ),
                  const SizedBox(height: 32),
                  ActionButton(
                    enabled: canLogin || isLoading,
                    loading: isLoading,
                    onPressed: login,
                  ),
                ],
                if (!isScanTab) ...[
                  const SizedBox(height: 48),
                  OtherLoginRow(
                    isLoading: isLoading,
                    showPasswordToggle: widget.enableSMS,
                    isSmsMode: isSmsMode,
                    onGithub: () => loginWithGithub(context),
                    onApple: _handleAppleLogin,
                    onToggleMode: toggleMode,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    if (isScanTab) {
      return QrLoginForm(
        authRepository: widget.authRepository,
        onLoginSuccess: widget.onLoginSuccess,
      );
    }
    if (isPasswordTab) {
      return PasswordLoginForm(strategy: passwordStrategy);
    }
    if (isEmailTab) {
      if (isSmsMode) {
        return EmailLoginForm(
          strategy: emailStrategy,
          isLoading: isLoading,
          onSendCode: () async {
            if (!agreed) {
              showToast('请先阅读并同意用户协议和隐私政策');
              return;
            }
            await emailStrategy.sendCode();
          },
        );
      }
      return PasswordLoginForm(strategy: passwordStrategy);
    }
    // phone tab
    if (!widget.enableSMS) {
      return PasswordLoginForm(strategy: passwordStrategy);
    }
    if (isSmsMode) {
      return SmsLoginForm(
        strategy: smsStrategy,
        isLoading: isLoading,
        onSendSms: () async {
          if (!agreed) {
            showToast('请先阅读并同意用户协议和隐私政策');
            return;
          }
          await smsStrategy.sendSms();
        },
      );
    }
    return PasswordLoginForm(strategy: passwordStrategy);
  }

  Future<void> _handleAppleLogin() async {
    if (!agreed) {
      showToast('请先阅读并同意用户协议和隐私政策');
      return;
    }
    if (!kApp.isIos) {
      showToast('Apple 登录仅支持 iOS 设备');
      return;
    }
    setState(() => isLoading = true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
      );
      final identityToken = credential.identityToken;
      if (identityToken == null) {
        showToast('未获取到 Apple 授权信息');
        return;
      }
      await loginWithAppleToken(identityToken);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        if (mounted) showToast('Apple 登录失败');
      }
    } catch (e) {
      if (mounted) showToast('Apple 登录失败');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}

class _BrandHeader extends StatelessWidget {
  final VoidCallback? onDebugDoubleTap;

  const _BrandHeader({this.onDebugDoubleTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onDoubleTap: onDebugDoubleTap,
          child: Image.asset('assets/images/logo.png', width: 72, height: 72),
        ),
        const SizedBox(height: 8),
        const Text(
          'FLASH IM',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '连接此刻，不止于此',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
