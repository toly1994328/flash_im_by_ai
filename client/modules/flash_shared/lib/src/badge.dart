import 'package:flutter/material.dart';

/// 角标尺寸
enum BadgeSize {
  /// 小号（侧边栏导航图标）：直径 16
  small,

  /// 中号（底部导航栏、会话列表）：直径 20
  medium,

  /// 大号（列表项强调）：直径 24
  large,
}

/// 未读数角标（红色正圆/胶囊 + 白色数字）
///
/// 一位数和两位数都是正圆，三位数（99+）为胶囊形。
///
/// ```dart
/// UnreadBadge(count: 5)
/// UnreadBadge(count: 99, size: BadgeSize.medium)
/// ```
class UnreadBadge extends StatelessWidget {
  final int count;
  final BadgeSize size;

  const UnreadBadge({
    super.key,
    required this.count,
    this.size = BadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final text = count > 99 ? '99+' : '$count';
    final diameter = switch (size) {
      BadgeSize.small => 16.0,
      BadgeSize.medium => 20.0,
      BadgeSize.large => 24.0,
    };
    final fontSize = switch (size) {
      BadgeSize.small => 9.0,
      BadgeSize.medium => 10.0,
      BadgeSize.large => 13.0,
    };

    // 三位数（99+）用胶囊形
    if (text.length > 2) {
      return Container(
        height: diameter,
        padding: EdgeInsets.symmetric(horizontal: diameter * 0.25),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(diameter / 2),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            height: 1,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      );
    }

    // 一位数和两位数都是正圆
    return Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: fontSize, height: 1),
      ),
    );
  }
}
