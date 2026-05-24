import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/auth_repository.dart';
import '../data/login_result.dart';
import '../logic/login/login_mixin.dart';
import 'components/sms_login_form.dart';
import 'components/password_login_form.dart';
import 'components/agreement_row.dart';
import 'components/action_button.dart';

/// 登录成功回调 — 由组装层注入，负责写入 session、跳转等
typedef OnLoginSuccess = void Function(LoginResult result);

class LoginPage extends StatefulWidget {
  final AuthRepository authRepository;
  final OnLoginSuccess onLoginSuccess;

  const LoginPage({
    super.key,
    required this.authRepository,
    required this.onLoginSuccess,
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 60),
              _BrandHeader(onDebugDoubleTap: () {
                smsStrategy.phoneCtrl.text = '13800010001';
              }),
              const SizedBox(height: 48),
              if (isSmsMode)
                SmsLoginForm(
                  strategy: smsStrategy,
                  isLoading: isLoading,
                  onSendSms: () async {
                    await smsStrategy.sendSms();
                  },
                )
              else
                PasswordLoginForm(strategy: passwordStrategy),
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
              _buildDivider(),
              const SizedBox(height: 20),
              _buildOtherLoginRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (Platform.isAndroid || Platform.isIOS) ...[
          _buildGithubItem(),
          const SizedBox(width: 24),
        ],
        _buildOtherLoginItem(
          icon: Icons.lock_outline,
          label: isSmsMode ? '密码登录' : '验证码登录',
          onTap: toggleMode,
        ),
      ],
    );
  }

  Widget _buildOtherLoginItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 22, color: const Color(0xFF555555)),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('其他登录方式', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ),
        const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
      ],
    );
  }

  Widget _buildGithubItem() {
    return GestureDetector(
      onTap: isLoading ? null : () => loginWithGithub(context),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/icons/github.svg',
            package: 'flash_auth',
            width: 48,
            height: 48,
          ),
          const SizedBox(height: 6),
          const Text('GitHub', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
        ],
      ),
    );
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
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        const SizedBox(height: 6),
        Text(
          '连接此刻，不止于此',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], letterSpacing: 4),
        ),
      ],
    );
  }
}
