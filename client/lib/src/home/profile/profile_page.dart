import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_im_core/flash_im_core.dart';

import 'settings_page.dart';
import 'my_qr_code_page.dart';

/// 微信风格"我"页面
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        final user = state.user;
        final hasPassword = state.hasPassword;

        return Scaffold(
          backgroundColor: const Color(0xFFEDEDED),
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.white,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
            child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // 顶部用户卡片
              UserCard(
                user: user,
                onTap: () => _pushPage(context, const EditProfilePage()),
              ),
              const SizedBox(height: 8),
              // 功能列表
              _buildGroup([
                _buildActionRow(
                  icon: Icons.qr_code,
                  iconColor: const Color(0xFF3B82F6),
                  label: '我的名片',
                  onTap: () => _pushPage(context, MyQrCodePage(user: user!)),
                ),
              ]),
              const SizedBox(height: 8),
              _buildGroup([
                _buildActionRow(
                  icon: Icons.settings_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  label: '设置',
                  onTap: () => _pushPage(
                    context,
                    SettingsPage(hasPassword: hasPassword),
                  ),
                ),
              ]),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildGroup(List<Widget> children) {
    return Container(
      color: Colors.white,
      child: Column(
        children: List.generate(children.length, (i) {
          return Column(
            children: [
              children[i],
              if (i < children.length - 1)
                Divider(height: 0.5, indent: 56, color: Colors.grey[200]),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<SessionCubit>(),
          child: page,
        ),
      ),
    );
  }
}
