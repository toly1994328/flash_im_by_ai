import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/logic/auth/auth_cubit.dart';
import '../../auth/logic/auth/auth_state.dart';
import '../../auth/data/repository/auth_repository.dart';
import 'set_password_page.dart';

class ProfilePage extends StatelessWidget {
  final AuthRepository authRepository;

  const ProfilePage({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state.user;
        final hasPassword = state.hasPassword;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFFEDEDED),
            elevation: 0.5,
            centerTitle: true,
            title: const Text('我', style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            children: [
              // 用户信息头部
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: user?.avatar.isNotEmpty == true
                          ? Image.network(
                              user!.avatar,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _defaultAvatar(),
                            )
                          : _defaultAvatar(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.nickname ?? '未知用户',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${user?.userId ?? '-'}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 信息条目
              _buildCell(
                icon: Icons.phone,
                label: '手机号',
                value: user?.phone ?? '-',
              ),

              const SizedBox(height: 8),

              // 设置密码
              _buildActionCell(
                icon: Icons.lock_outline,
                label: hasPassword ? '修改密码' : '设置密码',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<AuthCubit>(),
                      child: SetPasswordPage(
                        authRepository: authRepository,
                        hasPassword: hasPassword,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 退出登录
              Container(
                color: Colors.white,
                child: InkWell(
                  onTap: () async {
                    await authRepository.logout();
                    if (!context.mounted) return;
                    context.read<AuthCubit>().logout();
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
      },
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 32),
    );
  }

  Widget _buildCell({
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 2,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[800])),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 48),
      child: Divider(height: 0.5, thickness: 0.5, color: Colors.grey[200]),
    );
  }

  Widget _buildActionCell({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[800])),
              const Spacer(),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

}
