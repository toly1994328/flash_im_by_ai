import 'package:flutter/material.dart';
import '../../data/user.dart';
import 'identicon_avatar.dart';

/// 用户头像组件 — 根据 User 状态自动渲染 identicon / 网络图片 / 占位
class UserAvatar extends StatelessWidget {
  final User? user;
  final double size;
  final double borderRadius;
  final Color? backgroundColor;
  final double? paddingRatio;

  const UserAvatar({
    super.key,
    required this.user,
    this.size = 64,
    this.borderRadius = 8,
    this.backgroundColor,
    this.paddingRatio,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (user == null) {
      avatar = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(Icons.person, color: Colors.white, size: size * 0.55),
      );
    } else if (user!.hasCustomAvatar) {
      avatar = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          user!.avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child:
                Icon(Icons.person, color: Colors.white, size: size * 0.55),
          ),
        ),
      );
    } else {
      avatar = IdenticonAvatar(
          seed: user!.identiconSeed, size: size, borderRadius: borderRadius,
          backgroundColor: backgroundColor ?? const Color(0xFFEEEEEE),
          paddingRatio: paddingRatio ?? 0.15);
    }

    if (backgroundColor != null) {
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: avatar,
      );
    }
    return avatar;
  }
}

/// 微信风格用户卡片 — 头像 + 昵称 + 闪讯号 + 签名
class UserCard extends StatelessWidget {
  final User? user;
  final VoidCallback? onTap;

  const UserCard({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 40,
          left: 16,
          right: 16,
          bottom: 24,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            UserAvatar(user: user, size: 64),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.nickname ?? '未知用户',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '闪讯号: ${user?.userId ?? '-'}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  if (user?.signature.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      user!.signature,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }
}
