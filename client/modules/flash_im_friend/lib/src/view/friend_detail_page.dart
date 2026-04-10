import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/friend.dart';

/// 好友详情页（微信风格）
///
/// 顶部：头像 + 昵称 + 签名
/// 中间：设置项占位（备注、朋友圈等）
/// 底部：发消息 + 删除好友
class FriendDetailPage extends StatelessWidget {
  final Friend friend;
  final VoidCallback? onSendMessage;
  final VoidCallback? onDeleteFriend;

  const FriendDetailPage({
    super.key,
    required this.friend,
    this.onSendMessage,
    this.onDeleteFriend,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          _buildProfileCard(),
          const SizedBox(height: 10),
          _buildSettingItem(title: '设置备注和标签', onTap: () {}),
          const SizedBox(height: 10),
          _buildSettingItem(title: '朋友圈', onTap: () {}),
          _buildDivider(),
          _buildSettingItem(title: '更多信息', onTap: () {}),
          const Spacer(),
          _buildSendMessageButton(context),
          const SizedBox(height: 12),
          _buildDeleteButton(context),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

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
    return Container(
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

  Widget _buildSendMessageButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: onSendMessage,
          icon: const Icon(Icons.chat_bubble_outline, size: 20),
          label: const Text('发消息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: () => _confirmDelete(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red, width: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('删除好友', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
