import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_im_chat/flash_im_chat.dart' show MessageRepository;
import 'package:flash_im_core/flash_im_core.dart' show WsClient;
import 'package:fx_updater/fx_updater.dart';

import 'cloud_storage_card.dart';
import 'cloud_storage_page.dart';
import 'settings_page.dart';
import 'my_qr_code_page.dart';
import 'storage_quota_cubit.dart';
import 'storage_repository.dart';

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
              // 云空间卡片
              _buildCloudStorageCard(context),
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
                  trailing: const FxUpdateBadge(),
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

  Widget _buildCloudStorageCard(BuildContext context) {
    final MessageRepository msgRepo = context.read<MessageRepository>();
    final WsClient wsClient = context.read<WsClient>();
    return BlocProvider(
      create: (_) => StorageQuotaCubit(
        repository: StorageRepository(dio: msgRepo.dio),
        wsClient: wsClient,
      )..loadQuota(),
      child: BlocBuilder<StorageQuotaCubit, StorageQuotaState>(
        builder: (ctx, state) {
          if (state.status != StorageQuotaStatus.loaded || state.quota == null) {
            return const SizedBox.shrink();
          }
          return CloudStorageCard(
            quota: state.quota!,
            onTap: () {
              Navigator.of(ctx).push(MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: ctx.read<StorageQuotaCubit>(),
                  child: const CloudStoragePage(),
                ),
              ));
            },
          );
        },
      ),
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
    Widget? trailing,
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
            if (trailing != null) ...[trailing, const SizedBox(width: 8)],
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
