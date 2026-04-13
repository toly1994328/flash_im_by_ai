import 'dart:math';
import 'package:flutter/material.dart';
import 'avatar_widget.dart';

/// 群组宫格头像成员
class GroupAvatarMember {
  final String id;
  final String? avatarUrl;

  const GroupAvatarMember({required this.id, this.avatarUrl});
}

/// 群组宫格头像（微信风格）
///
/// 1人铺满，2人横排，3人上1下2，4人2x2，5-9人3列网格
class GroupAvatarWidget extends StatelessWidget {
  final List<GroupAvatarMember> members;
  final double size;
  final Color backgroundColor;
  final double spacing;
  final double? borderRadius;

  const GroupAvatarWidget({
    super.key,
    required this.members,
    this.size = 48,
    this.backgroundColor = const Color(0xFFDEE0E3),
    this.spacing = 2,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size * 0.1;
    final count = min(9, members.length);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: backgroundColor,
        padding: EdgeInsets.all(spacing),
        child: count == 0 ? const SizedBox.shrink() : _buildGrid(count),
      ),
    );
  }

  Widget _buildGrid(int count) {
    final innerSize = size - spacing * 2;
    return switch (count) {
      1 => _buildCell(0, innerSize),
      2 => _buildLayout2(innerSize),
      3 => _buildLayout3(innerSize),
      4 => _buildLayout4(innerSize),
      _ => _buildLayoutGrid(count, innerSize),
    };
  }

  Widget _buildLayout2(double innerSize) {
    final cellSize = (innerSize - spacing) / 2;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCell(0, cellSize),
            SizedBox(width: spacing),
            _buildCell(1, cellSize),
          ],
        ),
      ],
    );
  }

  Widget _buildLayout3(double innerSize) {
    final cellSize = (innerSize - spacing) / 2;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buildCell(0, cellSize)],
        ),
        SizedBox(height: spacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCell(1, cellSize),
            SizedBox(width: spacing),
            _buildCell(2, cellSize),
          ],
        ),
      ],
    );
  }

  Widget _buildLayout4(double innerSize) {
    final cellSize = (innerSize - spacing) / 2;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCell(0, cellSize),
            SizedBox(width: spacing),
            _buildCell(1, cellSize),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCell(2, cellSize),
            SizedBox(width: spacing),
            _buildCell(3, cellSize),
          ],
        ),
      ],
    );
  }

  Widget _buildLayoutGrid(int count, double innerSize) {
    final cellSize = (innerSize - spacing * 2) / 3;
    final items = List.generate(count, (i) => i);
    final rows = <Widget>[];

    for (var i = 0; i < items.length; i += 3) {
      final rowItems = items.sublist(i, min(i + 3, items.length));
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var j = 0; j < rowItems.length; j++) ...[
              if (j > 0) SizedBox(width: spacing),
              _buildCell(rowItems[j], cellSize),
            ],
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          rows[i],
        ],
      ],
    );
  }

  Widget _buildCell(int index, double cellSize) {
    final member = members[index];
    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: AvatarWidget(
        avatar: member.avatarUrl,
        size: cellSize,
        borderRadius: 1,
      ),
    );
  }
}
