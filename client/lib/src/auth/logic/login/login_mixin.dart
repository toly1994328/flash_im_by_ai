import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import '../auth/auth_cubit.dart';
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
      repo: widget.authRepository,
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
      final result = await currentStrategy.login(widget.authRepository);
      if (!mounted) return;
      context.read<AuthCubit>().login(
        token: result.loginResult.token,
        user: result.user,
        hasPassword: result.loginResult.hasPassword,
      );
      context.go('/home');
    } catch (e) {
      if (mounted) showToast('登录失败: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}
