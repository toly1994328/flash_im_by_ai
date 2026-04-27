import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../../data/search_models.dart';
import 'highlight_text.dart';

/// 好友搜索结果项组件
class FriendSearchItemWidget extends StatelessWidget {
  final FriendSearchItem item;
  final String keyword;
  final VoidCallback? onTap;

  const FriendSearchItemWidget({
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
            AvatarWidget(avatar: item.avatar, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: HighlightText(
                text: item.nickname,
                keyword: keyword,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
