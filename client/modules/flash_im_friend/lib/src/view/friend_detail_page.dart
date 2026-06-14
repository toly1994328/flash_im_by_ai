import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/friend.dart';

/// 好友详情页（微信风格）
///
/// 移动端：Scaffold + AppBar + 列表式布局
/// 桌面端（embedded）：无 AppBar，参考微信桌面端分组布局
class FriendDetailPage extends StatelessWidget {
  final Friend friend;
  final VoidCallback? onSendMessage;
  final VoidCallback? onDeleteFriend;

  /// 嵌入模式（桌面端面板内使用）：无 AppBar，紧凑分组布局
  final bool embedded;

  const FriendDetailPage({
    super.key,
    required this.friend,
    this.onSendMessage,
    this.onDeleteFriend,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (embedded) return _buildDesktopLayout(context);
    return _buildMobileLayout(context);
  }

  // ─── 移动端布局 ───

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        children: [
          _buildProfileCard(),
          const SizedBox(height: 10),
          _buildSettingItem(title: '设置备注和标签', onTap: () {}),
          const SizedBox(height: 10),
          _buildSettingItem(title: '朋友圈', onTap: () {}),
          _buildDivider(),
          _buildSettingItem(title: '更多信息', onTap: () {}),
          const SizedBox(height: 10),
          _buildMobileSendButton(),
          _buildMobileDeleteButton(context),
        ],
      ),
    );
  }

  // ─── 桌面端布局（参考微信桌面端） ───

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
            children: [
              // 顶部：头像 + 昵称 + ID
              _buildDesktopHeader(),
              const SizedBox(height: 24),
              const Divider(height: 0.5, color: Color(0xFFF0F0F0)),
              // 朋友资料
              _buildSectionTitle('朋友资料'),
              _buildInfoRow('备注', '未设置'),
              const SizedBox(height: 16),
              const Divider(height: 0.5, color: Color(0xFFF0F0F0)),
              // 更多信息
              _buildSectionTitle('更多信息'),
              if (friend.bio != null && friend.bio!.isNotEmpty)
                _buildInfoRow('个性签名', friend.bio!),
              _buildInfoRow('闪讯号', friend.friendId),
              const SizedBox(height: 32),
              const Divider(height: 0.5, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 32),
              // 底部操作按钮
              _buildDesktopActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvatarWidget(avatar: friend.avatar, size: 60, borderRadius: 8),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                friend.nickname,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 6),
              Text(
                '闪讯号：${friend.friendId}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
              ),
              if (friend.bio != null && friend.bio!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  friend.bio!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionIcon(
          icon: Icons.chat_bubble_outline,
          label: '发消息',
          color: const Color(0xFF3B82F6),
          onTap: onSendMessage,
        ),
        const SizedBox(width: 48),
        _buildActionIcon(
          icon: Icons.person_remove_outlined,
          label: '删除好友',
          color: const Color(0xFFF44336),
          onTap: () => _confirmDelete(context),
        ),
      ],
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  // ─── 移动端组件 ───

  Widget _buildProfileCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarWidget(avatar: friend.avatar, size: 64, borderRadius: 8),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  friend.nickname,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '闪讯号：${friend.friendId}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                if (friend.bio != null && friend.bio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    friend.bio!,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({required String title, VoidCallback? onTap}) {
    return Material(
      color: Colors.white,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16),
      child: const Divider(height: 0.5, thickness: 0.5),
    );
  }

  Widget _buildMobileSendButton() {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: onSendMessage,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
              bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF576B95)),
              SizedBox(width: 6),
              Text('发消息',
                  style: TextStyle(fontSize: 16, color: Color(0xFF576B95), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDeleteButton(BuildContext context) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: () => _confirmDelete(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('删除好友',
                  style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除好友「${friend.nickname}」'),
        content: const Text('删除后将解除双方好友关系'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDeleteFriend?.call();
            },
            child: const Text('确定删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
