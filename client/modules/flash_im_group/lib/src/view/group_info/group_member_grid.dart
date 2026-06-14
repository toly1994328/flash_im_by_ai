import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';

import '../../data/group_detail.dart';
import 'dashed_border_painter.dart';

/// 群成员网格区域（含 +/- 操作按钮、展开/收起）
class GroupMemberGrid extends StatefulWidget {
  final List<GroupMember> members;
  final String? ownerId;
  final bool isOwner;
  final String? baseUrl;
  final VoidCallback onInvite;
  final VoidCallback? onRemove;

  const GroupMemberGrid({
    super.key,
    required this.members,
    this.ownerId,
    required this.isOwner,
    this.baseUrl,
    required this.onInvite,
    this.onRemove,
  });

  @override
  State<GroupMemberGrid> createState() => _GroupMemberGridState();
}

class _GroupMemberGridState extends State<GroupMemberGrid> {
  static const int _membersPerRow = 5;
  static const int _defaultRows = 4;
  static const double _spacing = 12.0;
  bool _showAll = false;

  String? _resolveUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http') || path.startsWith('identicon:') || path.startsWith('grid:')) return path;
    if (widget.baseUrl != null) return '${widget.baseUrl}$path';
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final int actionCount = widget.isOwner ? 2 : 1;
    final int maxVisible = _showAll
        ? widget.members.length
        : min(_membersPerRow * _defaultRows - actionCount, widget.members.length);
    final List visibleMembers = widget.members.sublist(0, max(0, maxVisible));
    final bool hasMore = widget.members.length > maxVisible;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '群成员（${widget.members.length}）',
              style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final double tileW = (constraints.maxWidth - _spacing * (_membersPerRow - 1)) / _membersPerRow;
              return Wrap(
                spacing: _spacing,
                runSpacing: 12,
                children: [
                  ...visibleMembers.map((m) => _MemberTile(
                    member: m,
                    isOwner: m.userId == widget.ownerId,
                    avatarUrl: _resolveUrl(m.avatar),
                    tileWidth: tileW,
                  )),
                  _ActionTile(icon: Icons.add, onTap: widget.onInvite, tileWidth: tileW),
                  if (widget.isOwner)
                    _ActionTile(icon: Icons.remove, onTap: widget.onRemove!, tileWidth: tileW),
                ],
              );
            },
          ),
          if (hasMore || _showAll)
            GestureDetector(
              onTap: () => setState(() => _showAll = !_showAll),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showAll ? '收起' : '查看更多群成员',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                    ),
                    Icon(
                      _showAll ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 16, color: const Color(0xFF999999),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final GroupMember member;
  final bool isOwner;
  final String? avatarUrl;
  final double tileWidth;

  const _MemberTile({required this.member, required this.isOwner, this.avatarUrl, required this.tileWidth});

  @override
  Widget build(BuildContext context) {
    final double avatarSize = tileWidth - 8;
    return SizedBox(
      width: tileWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarWidget(avatar: avatarUrl, size: avatarSize, borderRadius: avatarSize * 0.1),
                if (isOwner)
                  Positioned(
                    right: -2, bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                      child: const Text('群主', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(member.nickname, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double tileWidth;

  const _ActionTile({required this.icon, required this.onTap, required this.tileWidth});

  @override
  Widget build(BuildContext context) {
    final double avatarSize = tileWidth - 8;
    return SizedBox(
      width: tileWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: CustomPaint(
              painter: DashedBorderPainter(color: const Color(0xFFCCCCCC), borderRadius: avatarSize * 0.1),
              child: SizedBox(
                width: avatarSize, height: avatarSize,
                child: Icon(icon, color: const Color(0xFFCCCCCC), size: avatarSize * 0.5),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text('', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
