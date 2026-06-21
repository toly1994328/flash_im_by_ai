import 'package:flutter/material.dart';
import 'identicon_avatar.dart';
import 'group_avatar_widget.dart';

/// 通用头像组件
///
/// 根据 avatar 字符串自动选择渲染方式：
/// - "identicon:xxx" → IdenticonAvatar
/// - "http(s)://..." → 网络图片
/// - 空或 null → 占位图标
class AvatarWidget extends StatelessWidget {
  final String? avatar;
  final double size;
  final double borderRadius;
  final Color backgroundColor;
  final double paddingRatio;
  final bool isVip;

  const AvatarWidget({
    super.key,
    this.avatar,
    this.size = 40,
    this.borderRadius = 4,
    this.backgroundColor = const Color(0xFFEEEEEE),
    this.paddingRatio = 0.15,
    this.isVip = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget avatarWidget = _buildAvatar();
    if (!isVip) return avatarWidget;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius + 2),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: avatarWidget,
    );
  }

  Widget _buildAvatar() {
    final av = avatar ?? '';
    if (av == 'identicon:system') {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(Icons.notifications, color: Colors.white, size: size * 0.55),
      );
    }
    if (av == 'identicon:team') {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(Icons.flash_on, color: Colors.white, size: size * 0.55),
      );
    }
    if (av.startsWith('system:')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(Icons.notifications, color: Colors.white, size: size * 0.55),
      );
    }
    if (av.startsWith('identicon:')) {
      final seed = av.substring('identicon:'.length);
      return IdenticonAvatar(
        seed: seed,
        size: size,
        borderRadius: borderRadius,
        backgroundColor: backgroundColor,
        paddingRatio: paddingRatio,
      );
    }
    if (av.startsWith('grid:')) {
      final avatarList = av.substring(5).split(',');
      final members = avatarList.asMap().entries.map((e) =>
        GroupAvatarMember(
          id: 'member_${e.key}',
          avatarUrl: e.value.trim().isNotEmpty ? e.value.trim() : null,
        ),
      ).toList();
      return GroupAvatarWidget(members: members, size: size, borderRadius: borderRadius);
    }
    if (av.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(av, width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder()),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(Icons.person, color: Colors.white, size: size * 0.55),
    );
  }
}
