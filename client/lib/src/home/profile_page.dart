import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oktoast/oktoast.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = state.user;
        final hasPassword = state.hasPassword;
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('我的'),
            backgroundColor: theme.colorScheme.inversePrimary,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: NetworkImage(user.avatar),
                    ),
                    const SizedBox(height: 16),
                    Text(user.nickname, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('ID: ${user.userId}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 32),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          _InfoTile(icon: Icons.phone, label: '手机号', value: user.phone),
                          const Divider(height: 1, indent: 56),
                          _InfoTile(icon: Icons.person, label: '昵称', value: user.nickname),
                          const Divider(height: 1, indent: 56),
                          _InfoTile(icon: Icons.badge, label: '用户 ID', value: '${user.userId}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 设置/修改密码
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => _showPasswordDialog(context, hasPassword),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          hasPassword ? '修改密码' : '设置密码',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 退出登录
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => context.read<AuthCubit>().logout(),
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
      },
    );
  }

  Future<void> _showPasswordDialog(BuildContext context, bool hasPassword) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(hasPassword ? '修改密码' : '设置密码'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: '请输入新密码（至少6位）'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (controller.text.length < 6) {
        showToast('密码至少6位');
        return;
      }
      try {
        final authCubit = context.read<AuthCubit>();
        await authCubit.authService.setPassword(controller.text);
        authCubit.onPasswordSet();
        showToast('密码设置成功');
      } catch (e) {
        showToast('设置失败: $e');
      }
    }
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
