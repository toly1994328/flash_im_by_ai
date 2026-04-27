import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../../data/search_models.dart';
import 'highlight_text.dart';

/// 群聊搜索结果项组件
class GroupSearchItemWidget extends StatelessWidget {
  final GroupSearchItem item;
  final String keyword;
  final VoidCallback? onTap;

  const GroupSearchItemWidget({
    super.key,
    required this.item,
    required this.keyword,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: HighlightText(
                      text: item.name ?? '群聊',
                      keyword: keyword,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${item.memberCount})',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final avatar = item.avatar;
    // 群头像以 grid: 开头时，解析为宫格头像
    if (avatar != null && avatar.startsWith('grid:')) {
      final parts = avatar.substring('grid:'.length).split(',');
      final members = parts
          .map((p) => GroupAvatarMember(id: p, avatarUrl: 'identicon:$p'))
          .toList();
      return GroupAvatarWidget(members: members, size: 40);
    }
    return AvatarWidget(avatar: avatar, size: 40);
  }
}
