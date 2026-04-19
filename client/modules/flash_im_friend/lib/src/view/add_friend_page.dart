import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_shared/flash_shared.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/friend_repository.dart';
import 'user_search_page.dart';
import 'scan_page.dart';

/// 加好友/群页面（微信风格）
///
/// 顶部搜索入口 → 功能入口列表 → 底部个人二维码
class AddFriendPage extends StatelessWidget {
  final FriendRepository repository;
  final VoidCallback? onSearchGroup;

  const AddFriendPage({super.key, required this.repository, this.onSearchGroup});

  /// 是否支持摄像头（Android/iOS 支持，桌面端不支持）
  bool get _supportCamera =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit>().state;
    final user = session.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('加好友/群'),
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // 搜索入口
          FlashSearchBar(
            hintText: '闪讯号 / 手机号 / 昵称',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => UserSearchPage(repository: repository),
            )),
          ),
          // 功能入口列表
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 10),
                _EntryItem(
                  icon: Icons.qr_code_scanner,
                  iconColor: const Color(0xFF3B82F6),
                  title: '扫一扫',
                  subtitle: '扫描二维码名片',
                  onTap: () {
                    if (_supportCamera) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ScanPage(repository: repository),
                      ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('当前平台不支持摄像头扫码')),
                      );
                    }
                  },
                ),
                _EntryItem(
                  icon: Icons.group_add_outlined,
                  iconColor: const Color(0xFF4CAF50),
                  title: '创建群聊',
                  subtitle: '与好友一起建群',
                  onTap: () {},
                ),
                _EntryItem(
                  icon: Icons.search,
                  iconColor: const Color(0xFFFF9800),
                  title: '搜索群聊',
                  subtitle: '搜索群名或群号加入群聊',
                  onTap: () => onSearchGroup?.call(),
                ),
                const SizedBox(height: 10),
                // 底部个人二维码
                if (user != null) _buildMyQrCode(context, user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyQrCode(BuildContext context, User user) {
    // 二维码内容：用户 ID，扫码后可直接添加好友
    final qrData = 'flashim://user/${user.userId}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      child: Column(
        children: [
          // 二维码卡片
          Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 用户信息
                Row(
                  children: [
                    AvatarWidget(avatar: user.avatar, size: 48, borderRadius: 8),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.nickname,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text('闪讯号：${user.userId}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 二维码 + 中间 logo（撑满宽度，1:1 比例）
                AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.maxWidth;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                            size: size,
                            padding: const EdgeInsets.all(4),
                            gapless: true,
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset('assets/images/logo.png'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text('扫一扫上面的二维码，添加我为好友',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 功能入口项
class _EntryItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EntryItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Color(0xFFCCCCCC)),
            ],
          ),
        ),
      ),
    );
  }
}
