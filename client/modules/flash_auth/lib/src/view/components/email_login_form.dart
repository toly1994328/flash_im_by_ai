import 'package:flutter/material.dart';
import '../../logic/login/strategy/email_login_strategy.dart';
import 'labeled_input.dart';

const _kPrimary = Color(0xFF3B82F6);

/// 邮箱验证码登录表单 — 邮箱 + 验证码两行输入
class EmailLoginForm extends StatelessWidget {
  final EmailLoginStrategy strategy;
  final bool isLoading;
  final VoidCallback onSendCode;

  const EmailLoginForm({
    super.key,
    required this.strategy,
    required this.isLoading,
    required this.onSendCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LabeledInput(
          label: '邮箱',
          child: TextField(
            controller: strategy.emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              hintText: '请输入邮箱',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        LabeledInput(
          label: '验证码',
          trailing: GestureDetector(
            onTap: strategy.canSendCode && !isLoading ? onSendCode : null,
            child: Text(
              strategy.countdown > 0 ? '${strategy.countdown}s' : '获取验证码',
              style: TextStyle(
                fontSize: 14,
                color: strategy.canSendCode && !isLoading ? _kPrimary : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          child: TextField(
            controller: strategy.codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              hintText: '请输入验证码',
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
