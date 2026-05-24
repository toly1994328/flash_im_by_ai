import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../logic/login/login_mixin.dart';

/// iOS 风格 Segment 切换（邮箱登录 / 手机号登录）
class LoginSegmentTab extends StatelessWidget {
  final LoginTab current;
  final ValueChanged<LoginTab> onChanged;

  const LoginSegmentTab({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<LoginTab>(
      groupValue: current,
      onValueChanged: (value) {
        if (value != null) onChanged(value);
      },
      padding: const EdgeInsets.all(4),
      children: {
        LoginTab.email: _buildItem(Icons.email_outlined, '邮箱登录'),
        LoginTab.phone: _buildItem(Icons.phone_android, '手机号登录'),
      },
    );
  }

  Widget _buildItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF555555)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
