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
  final String? conversationId;
  final VoidCallback? onSearchChat;

  /// 是否显示 AppBar（桌面端侧栏嵌入时设为 false）
  final bool showAppBar;

  const PrivateChatInfoPage({
    super.key,
    required this.peerName,
    this.peerAvatar,
    this.peerUserId,
    this.onAddMember,
    this.conversationId,
    this.onSearchChat,
    this.showAppBar = true,
  });

  void _confirmBlock(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('确认拉黑'),
        content: Text('拉黑后 $peerName 将无法给你发消息，同时解除好友关系。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              BlockUserEvent(userId: peerUserId!, nickname: peerName).emit();
              Navigator.of(context).pop();
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: showAppBar ? const Color(0xFFF5F5F5) : Colors.white,
      appBar: showAppBar
          ? AppBar(
              title: const Text('聊天详情'),
              backgroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      body: ListView(
        children: [
          if (showAppBar) const SizedBox(height: 10),
          _buildMemberSection(context),
          if (onSearchChat != null) ...[
            const SizedBox(height: 10),
            Material(
              color: Colors.white,
              child: ListTile(
                title: const Text('查找聊天内容', style: TextStyle(fontSize: 16, color: Color(0xFF333333))),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
                onTap: onSearchChat,
              ),
            ),
          ],
          if (peerUserId != null) ...[
            const SizedBox(height: 10),
            Material(
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.flag_outlined, color: Color(0xFF666666), size: 20),
                    title: const Text('举报', style: TextStyle(fontSize: 16, color: Color(0xFF333333))),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
                    onTap: () => ReportUserEvent(userId: peerUserId!, nickname: peerName).emit(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Divider(height: 0.5, thickness: 0.5, color: Colors.grey[200]),
                  ),
                  ListTile(
                    leading: const Icon(Icons.block, color: Colors.red, size: 20),
                    title: const Text('拉黑', style: TextStyle(fontSize: 16, color: Colors.red)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
                    onTap: () => _confirmBlock(context),
                  ),
                ],
              ),
            ),
          ],
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
