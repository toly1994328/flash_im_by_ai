import 'package:flash_shared/flash_shared.dart';
import 'package:flutter/material.dart';

/// 单聊详情页（仿微信风格）
///
/// 顶部对方头像 + "+"添加成员按钮
class PrivateChatInfoPage extends StatelessWidget {
  final String peerName;
  final String? peerAvatar;
  final String? peerUserId;
  final VoidCallback? onAddMember;

  const PrivateChatInfoPage({
    super.key,
    required this.peerName,
    this.peerAvatar,
    this.peerUserId,
    this.onAddMember,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('聊天详情'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          _buildMemberSection(context),
        ],
      ),
    );
  }

  Widget _buildMemberSection(BuildContext context) {
    const membersPerRow = 5;
    const spacing = 12.0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileW = (constraints.maxWidth - spacing * (membersPerRow - 1)) / membersPerRow;
          final avatarSize = tileW - 8;

          return Wrap(
            spacing: spacing,
            runSpacing: 24,
            children: [
              // 对方头像 + 昵称
              SizedBox(
                width: tileW,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AvatarWidget(avatar: peerAvatar, size: avatarSize, borderRadius: avatarSize * 0.1),
                    const SizedBox(height: 6),
                    Text(
                      peerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              // "+"添加成员按钮
              GestureDetector(
                onTap: onAddMember,
                child: SizedBox(
                  width: tileW,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
                          borderRadius: BorderRadius.circular(avatarSize * 0.1),
                        ),
                        child: const Icon(Icons.add, color: Color(0xFF999999), size: 24),
                      ),
                      const SizedBox(height: 6),
                      const Text('', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
