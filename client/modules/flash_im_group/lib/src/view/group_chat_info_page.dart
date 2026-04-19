import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/group_repository.dart';

/// 群聊详情页（最小版本）
///
/// 顶部成员网格 → 群主设置项 → 微信风格布局
class GroupChatInfoPage extends StatefulWidget {
  final GroupRepository repository;
  final String conversationId;
  final String? baseUrl;
  final String? currentUserId;

  const GroupChatInfoPage({
    super.key,
    required this.repository,
    required this.conversationId,
    this.baseUrl,
    this.currentUserId,
  });

  @override
  State<GroupChatInfoPage> createState() => _GroupChatInfoPageState();
}

class _GroupChatInfoPageState extends State<GroupChatInfoPage> {
  Map<String, dynamic>? _detail;
  bool _isLoading = true;
  String? _error;
  bool _joinVerification = false;
  bool _isUpdating = false;
  bool _showAllMembers = false;

  static const int _membersPerRow = 5;
  static const int _defaultRows = 2;
  static const double _spacing = 12.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final detail = await widget.repository.getGroupDetail(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _joinVerification = detail['join_verification'] as bool? ?? false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  bool get _isOwner {
    if (_detail == null || widget.currentUserId == null) return false;
    final ownerId = _detail!['owner_id'];
    return ownerId != null && ownerId.toString() == widget.currentUserId;
  }

  Future<void> _toggleJoinVerification(bool value) async {
    if (_isUpdating) return;
    setState(() { _isUpdating = true; _joinVerification = value; });
    try {
      await widget.repository.updateGroupSettings(
        widget.conversationId, joinVerification: value,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value ? '已开启入群验证' : '已关闭入群验证')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _joinVerification = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  String? _resolveUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http') || path.startsWith('identicon:') || path.startsWith('grid:')) return path;
    if (widget.baseUrl != null) return '${widget.baseUrl}$path';
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('群聊信息'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('重试')),
          ],
        ),
      );
    }
    if (_detail == null) return const SizedBox.shrink();

    final members = (_detail!['members'] as List?) ?? [];
    final name = _detail!['name'] as String? ?? '未命名群聊';
    final groupNo = _detail!['group_no'] as int? ?? 0;
    final ownerId = _detail!['owner_id']?.toString();

    return ListView(
      children: [
        const SizedBox(height: 10),
        // 成员网格
        _buildMemberSection(members, ownerId),
        const SizedBox(height: 10),
        // 群聊名称
        _buildSettingItem(title: '群聊名称', value: name),
        _buildDivider(),
        // 群号
        _buildSettingItem(title: '群号', value: groupNo.toString()),
        // 群主设置
        if (_isOwner) ...[
          const SizedBox(height: 10),
          _buildSwitchItem(
            title: '入群验证',
            subtitle: '开启后，新成员需要群主审批才能加入',
            value: _joinVerification,
            onChanged: _isUpdating ? null : _toggleJoinVerification,
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  /// 成员网格区域
  Widget _buildMemberSection(List members, String? ownerId) {
    final maxVisible = _showAllMembers
        ? members.length
        : min(_membersPerRow * _defaultRows, members.length);
    final visibleMembers = members.sublist(0, maxVisible);
    final hasMore = members.length > maxVisible;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '群成员（${members.length}）',
              style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileW = (constraints.maxWidth - _spacing * (_membersPerRow - 1)) / _membersPerRow;
              return Wrap(
                spacing: _spacing,
                runSpacing: 20,
                children: visibleMembers.map((m) {
                  final member = m as Map<String, dynamic>;
                  final userId = member['user_id']?.toString();
                  final isOwnerMember = userId == ownerId;
                  return _buildMemberTile(member, isOwnerMember, tileW);
                }).toList(),
              );
            },
          ),
          if (hasMore || _showAllMembers)
            GestureDetector(
              onTap: () => setState(() => _showAllMembers = !_showAllMembers),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showAllMembers ? '收起' : '查看更多群成员',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                    ),
                    Icon(
                      _showAllMembers ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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

  /// 单个成员 tile
  Widget _buildMemberTile(Map<String, dynamic> member, bool isOwner, double tileW) {
    final avatarSize = tileW - 8;
    final avatar = _resolveUrl(member['avatar'] as String?);
    final nickname = member['nickname'] as String? ?? '?';

    return SizedBox(
      width: tileW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarWidget(avatar: avatar, size: avatarSize, borderRadius: avatarSize * 0.1),
                if (isOwner)
                  Positioned(
                    right: -2, bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('群主',
                          style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(nickname,
              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
        ],
      ),
    );
  }

  /// 设置项（带箭头）
  Widget _buildSettingItem({required String title, String? value}) {
    return Container(
      color: Colors.white,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF333333))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
          ],
        ),
      ),
    );
  }

  /// Switch 设置项（iOS 风格）
  Widget _buildSwitchItem({
    required String title,
    String? subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF333333))),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 56,
            height: 32,
            child: FittedBox(
              fit: BoxFit.contain,
              child: CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: const Color(0xFF3B82F6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 分割线
  Widget _buildDivider() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16),
      child: const Divider(height: 0.5, thickness: 0.5),
    );
  }
}
