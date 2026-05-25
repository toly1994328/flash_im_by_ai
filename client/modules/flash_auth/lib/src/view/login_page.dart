import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
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
              LoginSegmentTab(current: tab, onChanged: switchTab, enableSMS: widget.enableSMS),
              const SizedBox(height: 16),
              _buildForm(),
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
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
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
      // enableSMS=false 时，phone tab 就是密码登录
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
    if (!Platform.isIOS) {
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
