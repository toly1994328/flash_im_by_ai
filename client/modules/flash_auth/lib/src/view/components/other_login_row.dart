import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 底部"其他登录方式"区域
class OtherLoginRow extends StatelessWidget {
  final bool isLoading;
  final bool showPasswordToggle;
  final bool isSmsMode;
  final VoidCallback onGithub;
  final VoidCallback onApple;
  final VoidCallback onToggleMode;

  const OtherLoginRow({
    super.key,
    required this.isLoading,
    required this.showPasswordToggle,
    required this.isSmsMode,
    required this.onGithub,
    required this.onApple,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDivider(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildItems(),
        ),
      ],
    );
  }

  List<Widget> _buildItems() {
    final items = <Widget>[];
    if (Platform.isIOS || Platform.isMacOS) {
      items.add(_buildAppleItem());
    }
    items.add(_buildGithubItem());
    if (showPasswordToggle) {
      items.add(_buildIconItem(
        icon: Icons.lock_outline,
        label: isSmsMode ? '密码登录' : '验证码登录',
        onTap: onToggleMode,
      ));
    }
    // 在 items 之间插入间距
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(const SizedBox(width: 24));
      }
    }
    return result;
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
      onTap: isLoading ? null : onGithub,
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

  Widget _buildAppleItem() {
    return GestureDetector(
      onTap: isLoading ? null : onApple,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.apple, size: 22, color: Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Apple', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildIconItem({required IconData icon, required String label, required VoidCallback onTap}) {
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
}
