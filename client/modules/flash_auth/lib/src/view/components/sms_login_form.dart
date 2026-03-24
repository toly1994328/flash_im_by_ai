import 'package:flutter/material.dart';
import '../../logic/login/strategy/sms_login_strategy.dart';
import 'labeled_input.dart';

const _kPrimary = Color(0xFF3B82F6);

/// 验证码登录表单 — 手机号 + 验证码两行输入
class SmsLoginForm extends StatelessWidget {
  final SmsLoginStrategy strategy;
  final bool isLoading;
  final VoidCallback onSendSms;

  const SmsLoginForm({
    super.key,
    required this.strategy,
    required this.isLoading,
    required this.onSendSms,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LabeledInput(
          label: '+86',
          child: TextField(
            controller: strategy.phoneCtrl,
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
        ),
        const SizedBox(height: 16),
        LabeledInput(
          label: '验证码',
          trailing: GestureDetector(
            onTap: strategy.canSendSms && !isLoading ? onSendSms : null,
            child: Text(
              strategy.countdown > 0 ? '${strategy.countdown}s' : '获取验证码',
              style: TextStyle(
                fontSize: 14,
                color: strategy.canSendSms && !isLoading ? _kPrimary : Colors.grey,
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
