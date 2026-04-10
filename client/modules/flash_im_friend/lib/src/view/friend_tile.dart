import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/friend.dart';

/// 好友列表项（微信风格）
///
/// 头像 40px + 昵称，分割线左缩进 68px（16 + 40 + 12）
class FriendTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDivider;

  const FriendTile({
    super.key,
    required this.friend,
    this.onTap,
    this.onLongPress,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  AvatarWidget(avatar: friend.avatar, size: 40, borderRadius: 6),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      friend.nickname,
                      style: const TextStyle(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showDivider)
            const Padding(
              padding: EdgeInsets.only(left: 68),
              child: Divider(height: 0.5, thickness: 0.5, color: Color(0xFFEEEEEE)),
            ),
        ],
      ),
    );
  }
}
