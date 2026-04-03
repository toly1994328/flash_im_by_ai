import 'package:flutter/material.dart';
import 'identicon_avatar.dart';

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

  const AvatarWidget({
    super.key,
    this.avatar,
    this.size = 40,
    this.borderRadius = 4,
    this.backgroundColor = const Color(0xFFEEEEEE),
    this.paddingRatio = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    final av = avatar ?? '';
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
    if (av.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(av, width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder()),
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
