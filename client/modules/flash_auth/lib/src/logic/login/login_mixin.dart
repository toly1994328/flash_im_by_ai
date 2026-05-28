import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import '../../data/device_info.dart';
import '../../view/github_auth_page.dart';
import '../../view/login_page.dart';
import 'strategy/login_strategy.dart';
import 'strategy/sms_login_strategy.dart';
import 'strategy/password_login_strategy.dart';
import 'strategy/email_login_strategy.dart';

enum LoginTab { email, phone, password, scan }

enum LoginMode {
  sms('sms'),
  password('password');

  final String value;
  const LoginMode(this.value);
}

mixin LoginMixin on State<LoginPage> {
  late final SmsLoginStrategy smsStrategy;
  late final PasswordLoginStrategy passwordStrategy;
  late final EmailLoginStrategy emailStrategy;

  LoginTab tab = LoginTab.email;
  LoginMode mode = LoginMode.sms;
  bool agreed = false;
  bool isLoading = false;

  bool get isEmailTab => tab == LoginTab.email;
  bool get isScanTab => tab == LoginTab.scan;
  bool get isPasswordTab => tab == LoginTab.password;
  bool get isSmsMode => mode == LoginMode.sms;

  /// 当前激活的策略
  LoginStrategy get currentStrategy {
    if (isEmailTab) return isSmsMode ? emailStrategy : passwordStrategy;
    if (tab == LoginTab.password) return passwordStrategy;
    if (!widget.enableSMS) return passwordStrategy;
    return isSmsMode ? smsStrategy : passwordStrategy;
  }

  bool get canLogin => !isScanTab && agreed && !isLoading && currentStrategy.isValid;

  void initMixin() {
    smsStrategy = SmsLoginStrategy(
      sendSmsCallback: (phone) => widget.authRepository.sendSms(phone),
      refresh: () => setState(() {}),
    );
    passwordStrategy = PasswordLoginStrategy(
      refresh: () => setState(() {}),
    );
    emailStrategy = EmailLoginStrategy(
      sendEmailCodeCallback: (email) => widget.authRepository.sendEmailCode(email),
      refresh: () => setState(() {}),
    );
    smsStrategy.listen();
    passwordStrategy.listen();
    emailStrategy.listen();
  }

  void disposeMixin() {
    smsStrategy.dispose();
    passwordStrategy.dispose();
    emailStrategy.dispose();
  }

  void switchTab(LoginTab newTab) {
    setState(() {
      tab = newTab;
      mode = LoginMode.sms;
    });
  }

  void toggleMode() {
    setState(() {
      mode = isSmsMode ? LoginMode.password : LoginMode.sms;
    });
  }

  Future<void> login() async {
    setState(() => isLoading = true);
    try {
      final deviceInfo = await DeviceInfo.collect();
      final result = await currentStrategy.login(widget.authRepository, deviceInfo: deviceInfo);
      if (!mounted) return;
      widget.onLoginSuccess(result);
    } catch (e) {
      if (mounted) showToast('登录失败: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loginWithGithub(BuildContext context) async {
    if (!agreed) {
      showToast('请先阅读并同意用户协议和隐私政策');
      return;
    }

    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const GitHubAuthPage()),
    );
    if (code == null || !mounted) return;

    setState(() => isLoading = true);
    try {
      final deviceInfo = await DeviceInfo.collect();
      final result = await widget.authRepository.loginWithGithub(code, deviceInfo: deviceInfo);
      if (!mounted) return;
      widget.onLoginSuccess(result);
    } catch (e) {
      if (mounted) showToast('GitHub 登录失败: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Apple 登录（由 LoginPage 传入 identityToken）
  Future<void> loginWithAppleToken(String identityToken) async {
    setState(() => isLoading = true);
    try {
      final deviceInfo = await DeviceInfo.collect();
      final result = await widget.authRepository.loginWithApple(identityToken, deviceInfo: deviceInfo);
      if (!mounted) return;
      widget.onLoginSuccess(result);
    } catch (e) {
      if (mounted) showToast('Apple 登录失败');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}
