import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/friend.dart';
import '../logic/friend_cubit.dart';
import '../logic/friend_state.dart';
import 'indexed_contact_list.dart';

/// 通讯录页面（微信风格）
///
/// 顶部固定入口（好友申请 + badge）→ 字母索引好友列表 → 底部联系人计数
class FriendListPage extends StatelessWidget {
  final void Function(Friend friend)? onFriendTap;
  final VoidCallback? onAddFriendTap;
  final VoidCallback? onRequestsTap;
  final VoidCallback? onSearchGroupTap;
  final VoidCallback? onGroupNotificationsTap;
  final int groupNotificationCount;

  const FriendListPage({
    super.key,
    this.onFriendTap,
    this.onAddFriendTap,
    this.onRequestsTap,
    this.onSearchGroupTap,
    this.onGroupNotificationsTap,
    this.groupNotificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('通讯录'),
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: onAddFriendTap,
          ),
        ],
      ),
      body: BlocBuilder<FriendCubit, FriendState>(
        builder: (context, state) {
          if (state.isLoading && state.friends.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final headerItems = [
            _ContactHeaderItem(
              icon: Icons.person_add,
              iconColor: const Color(0xFFF97D1C),
              title: '新的朋友',
              badge: state.pendingCount,
              onTap: () => onRequestsTap?.call(),
            ),
            _ContactHeaderItem(
              icon: Icons.group,
              iconColor: const Color(0xFF2196F3),
              title: '群通知',
              badge: groupNotificationCount,
              onTap: () => onGroupNotificationsTap?.call(),
            ),
            _ContactHeaderItem(
              icon: Icons.search,
              iconColor: const Color(0xFF4CAF50),
              title: '搜索群聊',
              onTap: () => onSearchGroupTap?.call(),
            ),
          ];

          if (state.friends.isEmpty) {
            return Column(
              children: [
                ...headerItems,
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 56, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text('暂无好友', style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('点击右上角 + 添加好友', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return IndexedContactList(
            friends: state.friends,
            headerItems: headerItems,
            onFriendTap: onFriendTap,
            onFriendLongPress: (friend) => _confirmDelete(context, friend),
            onRefresh: () => context.read<FriendCubit>().loadFriends(),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Friend friend) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除好友'),
        content: Text('确定删除好友 ${friend.nickname} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<FriendCubit>().deleteFriend(friend.friendId);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// 通讯录顶部固定入口项（微信风格）
class _ContactHeaderItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int badge;
  final VoidCallback onTap;

  const _ContactHeaderItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 15)),
                  ),
                  if (badge > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : badge.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 68),
            child: Divider(height: 0.5, thickness: 0.5, color: Color(0xFFEEEEEE)),
          ),
        ],
      ),
    );
  }
}
