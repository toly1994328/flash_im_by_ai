import 'package:flash_auth/flash_auth.dart';
import 'package:flash_im_core/flash_im_core.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../application/config.dart';
import 'about_page.dart';

/// 设置页面（微信风格分组列表）
class SettingsPage extends StatelessWidget {
  final bool hasPassword;

  const SettingsPage({super.key, required this.hasPassword});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: const Color(0xFFEDEDED),
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        children: [
          // ─── 账号 ───
          _buildSectionHeader('账号'),
          _buildGroup([
            _buildItem(icon: Icons.person_outline, label: '个人资料', onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const EditProfilePage(),
              ));
            }),
            _buildItem(icon: Icons.lock_outline, label: hasPassword ? '修改密码' : '设置密码', onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => hasPassword ? const ChangePasswordPage() : const SetPasswordPage(),
              ));
            }),
            _buildItem(icon: Icons.delete_outline, label: '注销账号', onTap: () => _confirmDeleteAccount(context)),
          ]),

          // ─── 关于 ───
          _buildSectionHeader('关于'),
          _buildGroup([
            _buildItem(icon: Icons.info_outline, label: '关于闪讯', onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutPage()));
            }),
            _buildItem(icon: Icons.description_outlined, label: '用户协议', onTap: () => _openPolicy(context, '用户协议', '/static/agreement.html')),
            _buildItem(icon: Icons.shield_outlined, label: '隐私政策', onTap: () => _openPolicy(context, '隐私政策', '/static/privacy.html')),
          ]),

          // ─── 退出登录 ───
          const SizedBox(height: 24),
          Container(
            color: Colors.white,
            child: InkWell(
              onTap: () async {
                context.read<WsClient>().disconnect();
                await context.read<SessionCubit>().deactivate();
                if (!context.mounted) return;
                context.go('/login');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Text('退出登录', style: TextStyle(fontSize: 16, color: Colors.red)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 6),
      child: Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
    );
  }

  Widget _buildGroup(List<Widget> items) {
    return Container(
      color: Colors.white,
      child: Column(
        children: List.generate(items.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Divider(height: 0.5, thickness: 0.5, color: Colors.grey[200]),
            );
          }
          return items[i ~/ 2];
        }),
      ),
    );
  }

  Widget _buildItem({IconData? icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16, color: Color(0xFF333333)))),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _openPolicy(BuildContext context, String title, String path) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PolicyPage(title: title, url: '${AppConfig.baseUrl}$path'),
    ));
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('注销账号', style: TextStyle(fontSize: 17)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ 注销后以下数据将被永久删除：',
              style: TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text('• 账号信息和个人资料', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
            Text('• 所有聊天记录', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
            Text('• 好友关系和群聊', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
            SizedBox(height: 12),
            Text(
              '如需注销，请发送邮件至 1981462002@qq.com，我们将在 7 个工作日内审核处理。',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('我知道了', style: TextStyle(color: Color(0xFF3B82F6))),
          ),
        ],
      ),
    );
  }

}
