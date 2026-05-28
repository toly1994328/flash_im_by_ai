import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../logic/login/login_mixin.dart';

/// iOS 风格 Segment 切换
/// isDesktop=true: 邮箱登录 / 手机号登录(可选) / 密码登录 / 扫码登录
/// isDesktop=false: 保持原有两 Tab
class LoginSegmentTab extends StatelessWidget {
  final LoginTab current;
  final ValueChanged<LoginTab> onChanged;
  final bool enableSMS;
  final bool isDesktop;

  const LoginSegmentTab({
    super.key,
    required this.current,
    required this.onChanged,
    this.enableSMS = true,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return _buildDesktopTabs();
    }
    return _buildMobileTabs();
  }

  Widget _buildDesktopTabs() {
    final children = <LoginTab, Widget>{
      LoginTab.email: _buildItem(Icons.email_outlined, '邮箱登录'),
      if (enableSMS) LoginTab.phone: _buildItem(Icons.phone_android, '手机号'),
      LoginTab.password: _buildItem(Icons.lock_outline, '密码登录'),
      LoginTab.scan: _buildItem(Icons.qr_code, '扫码登录'),
    };

    return CupertinoSlidingSegmentedControl<LoginTab>(
      groupValue: current,
      onValueChanged: (value) {
        if (value != null) onChanged(value);
      },
      padding: const EdgeInsets.all(4),
      children: children,
    );
  }

  Widget _buildMobileTabs() {
    if (enableSMS) {
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
    return CupertinoSlidingSegmentedControl<LoginTab>(
      groupValue: current,
      onValueChanged: (value) {
        if (value != null) onChanged(value);
      },
      padding: const EdgeInsets.all(4),
      children: {
        LoginTab.email: _buildItem(Icons.email_outlined, '邮箱登录'),
        LoginTab.phone: _buildItem(Icons.lock_outline, '密码登录'),
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
