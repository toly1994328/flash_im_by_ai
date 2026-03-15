import 'package:flutter/material.dart';
import '../api/auth_api.dart';
import '../model/user_profile.dart';
import 'login_page.dart';

/// 个人信息页
class ProfilePage extends StatelessWidget {
  final AuthApi api;
  final UserProfile profile;

  const ProfilePage({super.key, required this.api, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人信息'),
        backgroundColor: theme.colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 头像
                CircleAvatar(
                  radius: 48,
                  backgroundImage: NetworkImage(profile.avatar),
                ),
                const SizedBox(height: 16),
                Text(profile.nickname, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('ID: ${profile.userId}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                const SizedBox(height: 32),

                // 信息卡片
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      _InfoTile(icon: Icons.phone, label: '手机号', value: profile.phone),
                      const Divider(height: 1, indent: 56),
                      _InfoTile(icon: Icons.person, label: '昵称', value: profile.nickname),
                      const Divider(height: 1, indent: 56),
                      _InfoTile(icon: Icons.badge, label: '用户 ID', value: '${profile.userId}'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Token 预览
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('JWT Token', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        api.token ?? '',
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.black54),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 退出登录
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      api.logout();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('退出登录', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15)),
    );
  }
}
