import 'package:flutter/material.dart';
import '../../logic/login/strategy/password_login_strategy.dart';
import 'labeled_input.dart';

/// 密码登录表单 — 账号 + 密码两行输入
class PasswordLoginForm extends StatelessWidget {
  final PasswordLoginStrategy strategy;

  const PasswordLoginForm({
    super.key,
    required this.strategy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LabeledInput(
          label: '账号',
          child: TextField(
            controller: strategy.accountCtrl,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              hintText: '手机号/用户名/邮箱',
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        LabeledInput(
          label: '密码',
          child: TextField(
            controller: strategy.passwordCtrl,
            obscureText: true,
            maxLength: 20,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              hintText: '请输入密码',
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
