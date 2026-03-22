import 'package:flutter/material.dart';
import '../data/repository/auth_repository.dart';
import '../logic/login/login_mixin.dart';
import 'components/sms_login_form.dart';
import 'components/password_login_form.dart';
import 'components/agreement_row.dart';
import 'components/action_button.dart';

class LoginPage extends StatefulWidget {
  final AuthRepository authRepository;

  const LoginPage({super.key, required this.authRepository});

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
              const _BrandHeader(),
              const SizedBox(height: 48),
              if (isSmsMode)
                SmsLoginForm(
                  strategy: smsStrategy,
                  isLoading: isLoading,
                  onSendSms: () async {
                    setState(() => isLoading = true);
                    await smsStrategy.sendSms();
                    if (mounted) setState(() => isLoading = false);
                  },
                )
              else
                PasswordLoginForm(strategy: passwordStrategy),
              const SizedBox(height: 36),
              AgreementRow(
                checked: agreed,
                onTap: () => setState(() => agreed = !agreed),
              ),
              const SizedBox(height: 32),
              ActionButton(
                enabled: canLogin,
                loading: isLoading,
                onPressed: login,
              ),
              const SizedBox(height: 24),
              _buildModeToggle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return GestureDetector(
      onTap: toggleMode,
      child: Text(
        isSmsMode ? '使用密码登录 →' : '使用验证码登录 →',
        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset('assets/images/logo.png', width: 72, height: 72),
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
