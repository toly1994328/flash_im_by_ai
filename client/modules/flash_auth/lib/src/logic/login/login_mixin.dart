import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import '../../data/device_info.dart';
import '../../view/github_auth_page.dart';
import '../../view/login_page.dart';
import 'strategy/login_strategy.dart';
import 'strategy/sms_login_strategy.dart';
import 'strategy/password_login_strategy.dart';

enum LoginMode {
  sms('sms'),
  password('password');

  final String value;
  const LoginMode(this.value);
}

mixin LoginMixin on State<LoginPage> {
  late final SmsLoginStrategy smsStrategy;
  late final PasswordLoginStrategy passwordStrategy;

  LoginMode mode = LoginMode.sms;
  bool agreed = false;
  bool isLoading = false;

  bool get isSmsMode => mode == LoginMode.sms;

  /// 当前激活的策略
  LoginStrategy get currentStrategy => isSmsMode ? smsStrategy : passwordStrategy;

  bool get canLogin => agreed && !isLoading && currentStrategy.isValid;

  void initMixin() {
    smsStrategy = SmsLoginStrategy(
      sendSmsCallback: (phone) => widget.authRepository.sendSms(phone),
      refresh: () => setState(() {}),
    );
    passwordStrategy = PasswordLoginStrategy(
      refresh: () => setState(() {}),
    );
    smsStrategy.listen();
    passwordStrategy.listen();
  }

  void disposeMixin() {
    smsStrategy.dispose();
    passwordStrategy.dispose();
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
}
