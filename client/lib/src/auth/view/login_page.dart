import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oktoast/oktoast.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';

const _kPrimary = Color(0xFF3B82F6);

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    return BlocProvider(
      create: (_) => LoginCubit(authCubit.authService),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _phoneCtrl = TextEditingController();
  final _credCtrl = TextEditingController();
  bool _agreed = false;
  int _countdown = 0;
  Timer? _timer;

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() { _countdown--; });
      if (_countdown <= 0) t.cancel();
    });
  }

  bool get _canSendSms => _countdown <= 0;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _credCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is SmsSent) {
          _credCtrl.text = state.code; // 测试阶段自动填入
          _startCountdown();
        } else if (state is LoginSuccess) {
          context.read<AuthCubit>().onLoginSuccess(
            state.user,
            state.result.hasPassword,
          );
        } else if (state is LoginFailure) {
          showToast(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 80),
                // 品牌标题
                const Text(
                  'FLASH IM',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '闪讯',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], letterSpacing: 4),
                ),
                const SizedBox(height: 56),
                _buildPhoneInput(),
                const SizedBox(height: 8),
                _buildCredentialInput(),
                const SizedBox(height: 28),
                _buildAgreement(),
                const SizedBox(height: 24),
                _buildLoginButton(),
                const SizedBox(height: 20),
                _buildModeSwitch(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return _InputRow(
      label: '+86',
      child: TextField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        maxLength: 11,
        style: const TextStyle(fontSize: 16),
        decoration: const InputDecoration(
          hintText: '请输入手机号',
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCredentialInput() {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (prev, curr) => curr is LoginInitial,
      builder: (context, state) {
        final isSms = context.read<LoginCubit>().isSmsMode;
        return _InputRow(
          label: isSms ? '验证码' : '密码',
          trailing: isSms
              ? GestureDetector(
                  onTap: _canSendSms
                      ? () => context.read<LoginCubit>().sendSms(_phoneCtrl.text.trim())
                      : null,
                  child: Text(
                    _countdown > 0 ? '${_countdown}s' : '获取验证码',
                    style: TextStyle(
                      fontSize: 14,
                      color: _canSendSms ? _kPrimary : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : null,
          child: TextField(
            controller: _credCtrl,
            keyboardType: isSms ? TextInputType.number : TextInputType.visiblePassword,
            obscureText: !isSms,
            maxLength: isSms ? 6 : 32,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: isSms ? '请输入验证码' : '请输入密码',
              border: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAgreement() {
    return GestureDetector(
      onTap: () => setState(() => _agreed = !_agreed),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CheckIcon(checked: _agreed),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                children: const [
                  TextSpan(text: '登录即代表您同意'),
                  TextSpan(text: '《用户协议》', style: TextStyle(color: _kPrimary)),
                  TextSpan(text: '和'),
                  TextSpan(text: '《隐私政策》', style: TextStyle(color: _kPrimary)),
                  TextSpan(text: '，未注册绑定的手机号验证成功后将自动注册'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final loading = state is LoginLoading || state is SmsSending;
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: loading
                ? null
                : () {
                    if (!_agreed) {
                      showToast('请先同意用户协议');
                      return;
                    }
                    context.read<LoginCubit>().login(
                      _phoneCtrl.text.trim(),
                      _credCtrl.text.trim(),
                    );
                  },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('登录', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ),
        );
      },
    );
  }

  Widget _buildModeSwitch() {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (prev, curr) => curr is LoginInitial,
      builder: (context, state) {
        final isSms = context.read<LoginCubit>().isSmsMode;
        return GestureDetector(
          onTap: () {
            _credCtrl.clear();
            context.read<LoginCubit>().toggleMode();
          },
          child: Text(
            isSms ? '使用密码登录 →' : '使用验证码登录 →',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        );
      },
    );
  }
}

/// 底部分割线风格的输入行
class _InputRow extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget? trailing;

  const _InputRow({required this.label, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.only(right: 12),
            color: _kPrimary.withValues(alpha: 0.4),
          ),
          Expanded(child: child),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 自定义圆角勾选图标
class _CheckIcon extends StatelessWidget {
  final bool checked;
  const _CheckIcon({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: checked ? _kPrimary : Colors.transparent,
        border: Border.all(
          color: checked ? _kPrimary : Colors.grey[400]!,
          width: 1.2,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 10, color: Colors.white)
          : null,
    );
  }
}
