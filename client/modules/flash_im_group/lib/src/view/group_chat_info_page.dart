import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/group_repository.dart';
import 'create_group_page.dart';
import 'edit_group_name_page.dart';
import 'group_announcement_page.dart';

/// 群聊详情页（v0.0.3 完整版本）
///
/// 顶部成员网格（含 +/- 操作按钮）→ 群设置项 → 群管理 → 底部操作按钮
class GroupChatInfoPage extends StatefulWidget {
  final GroupRepository repository;
  final String conversationId;
  final String? baseUrl;
  final String? currentUserId;
  final Future<List<SelectableMember>> Function()? friendsFetcher;
  final VoidCallback? onLeaveOrDisband;

  const GroupChatInfoPage({
    super.key,
    required this.repository,
    required this.conversationId,
    this.baseUrl,
    this.currentUserId,
    this.friendsFetcher,
    this.onLeaveOrDisband,
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
  static const int _defaultRows = 4;
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

  // ─── 邀请入群 ───

  Future<void> _showInvitePage() async {
    if (widget.friendsFetcher == null) return;
    try {
      final friends = await widget.friendsFetcher!();
      if (!mounted) return;
      // 当前群成员 ID 集合作为 initialSelectedIds（预选不可取消）
      final members = (_detail?['members'] as List?) ?? [];
      final existingIds = members
          .map((m) => (m as Map<String, dynamic>)['user_id']?.toString())
          .whereType<String>()
          .toSet();

      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CreateGroupPage(
          members: friends,
          initialSelectedIds: existingIds,
          onCreated: (result) async {
            // 只取新增的成员 ID（过滤掉已有成员）
            final newMemberIds = result.memberIds
                .where((id) => !existingIds.contains(id.toString()))
                .toList();
            if (newMemberIds.isEmpty) {
              Navigator.of(context).pop();
              return;
            }
            try {
              final count = await widget.repository.addMembers(
                widget.conversationId, newMemberIds,
              );
              if (!mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('成功邀请 $count 人入群')),
              );
              _load();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('邀请失败：$e')),
                );
              }
            }
          },
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取好友列表失败：$e')),
        );
      }
    }
  }

  // ─── 踢人 ───

  void _showRemoveSheet() {
    final members = (_detail?['members'] as List?) ?? [];
    final ownerId = _detail?['owner_id']?.toString();
    // 排除群主，转为 SelectableMember
    final removable = members
        .cast<Map<String, dynamic>>()
        .where((m) => m['user_id']?.toString() != ownerId)
        .toList();

    if (removable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可移除的成员')),
      );
      return;
    }

    final selectableMembers = removable.map((m) {
      final uid = m['user_id']?.toString() ?? '';
      final nickname = m['nickname'] as String? ?? '?';
      final avatar = _resolveUrl(m['avatar'] as String?);
      return SelectableMember(
        id: uid,
        nickname: nickname,
        avatar: avatar,
        letter: PinyinUtil.getFirstLetter(nickname),
      );
    }).toList();

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MemberPickerPage(
        members: selectableMembers,
        title: '移除成员',
        confirmLabel: '移除',
        isRemoveMode: true,
        onConfirm: (result) async {
          Navigator.of(context).pop(); // 关闭选人页
          // 逐个移除选中的成员
          final ids = result.newIds;
          int removed = 0;
          for (final uid in ids) {
            try {
              await widget.repository.removeMember(widget.conversationId, int.parse(uid));
              removed++;
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('移除失败：$e')),
                );
              }
            }
          }
          if (mounted && removed > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已移除 $removed 人')),
            );
            _load();
          }
        },
      ),
    ));
  }

  // ─── 转让群主 ───

  void _showTransferSheet() {
    final members = (_detail?['members'] as List?) ?? [];
    // 排除自己
    final transferable = members
        .cast<Map<String, dynamic>>()
        .where((m) => m['user_id']?.toString() != widget.currentUserId)
        .toList();

    if (transferable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可转让的成员')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('转让群主', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
            ),
            const Divider(height: 0.5),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: transferable.length,
                itemBuilder: (_, index) {
                  final member = transferable[index];
                  final avatar = _resolveUrl(member['avatar'] as String?);
                  final nickname = member['nickname'] as String? ?? '?';
                  final userId = member['user_id'] as int?;
                  return ListTile(
                    leading: AvatarWidget(avatar: avatar, size: 40, borderRadius: 6),
                    title: Text(nickname, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _confirmTransfer(nickname, userId);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmTransfer(String nickname, int? userId) async {
    if (userId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('转让群主'),
        content: Text('确定将群主转让给 $nickname？转让后你将变为普通成员。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消', style: TextStyle(color: Color(0xFF999999))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定', style: TextStyle(color: Color(0xFF3B82F6))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.transferOwner(widget.conversationId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已将群主转让给 $nickname')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('转让失败：$e')),
        );
      }
    }
  }

  // ─── 解散群聊 ───

  Future<void> _confirmDisband() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('解散群聊'),
        content: const Text('解散后，所有群成员将被移出，且无法恢复。确定解散？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消', style: TextStyle(color: Color(0xFF999999))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('解散', style: TextStyle(color: Color(0xFFF44336))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.disbandGroup(widget.conversationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('群聊已解散')),
        );
        widget.onLeaveOrDisband?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解散失败：$e')),
        );
      }
    }
  }

  // ─── 退出群聊 ───

  Future<void> _confirmLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('退出群聊'),
        content: const Text('退出后将不再接收此群聊消息，确定退出？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消', style: TextStyle(color: Color(0xFF999999))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('退出', style: TextStyle(color: Color(0xFFF44336))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.leaveGroup(widget.conversationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已退出群聊')),
        );
        widget.onLeaveOrDisband?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('退出失败：$e')),
        );
      }
    }
  }

  // ─── 编辑群名 ───

  Future<void> _showEditNameDialog() async {
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('仅群主可修改群名')),
      );
      return;
    }
    final currentName = _detail?['name'] as String? ?? '';
    final avatar = _resolveUrl(_detail?['avatar'] as String?);
    final newName = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => EditGroupNamePage(
        currentName: currentName,
        avatar: avatar,
      ),
    ));
    if (newName == null || newName.isEmpty || newName == currentName) return;
    try {
      await widget.repository.updateGroup(widget.conversationId, name: newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('群名已修改')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('修改失败：$e')),
        );
      }
    }
  }

  // ─── 编辑群头像（占位） ───

  Widget _buildGroupAvatar(String? avatar, double size) {
    final resolved = _resolveUrl(avatar);
    if (resolved != null && resolved.startsWith('grid:')) {
      final avatarList = resolved.substring(5).split(',');
      final members = <GroupAvatarMember>[];
      for (var i = 0; i < avatarList.length; i++) {
        final a = avatarList[i].trim();
        members.add(GroupAvatarMember(
          id: 'member_$i',
          avatarUrl: a.isNotEmpty ? a : null,
        ));
      }
      return GroupAvatarWidget(members: members, size: size, borderRadius: 4);
    }
    return AvatarWidget(avatar: resolved, size: size, borderRadius: 4);
  }

  void _showEditAvatar() {
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('仅群主可修改群头像')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('群头像修改功能开发中')),
    );
  }

  // ─── 群管理 BottomSheet ───

  void _showManageSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Color(0xFF333333)),
              title: const Text('转让群主', style: TextStyle(fontSize: 16, color: Color(0xFF333333))),
              onTap: () {
                Navigator.of(ctx).pop();
                _showTransferSheet();
              },
            ),
            const Divider(height: 0.5),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Color(0xFFF44336)),
              title: const Text('解散群聊', style: TextStyle(fontSize: 16, color: Color(0xFFF44336))),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmDisband();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── 群公告 ───

  Future<void> _openAnnouncement() async {
    final currentAnnouncement = _detail?['announcement'] as String?;
    final result = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => GroupAnnouncementPage(
        repository: widget.repository,
        conversationId: widget.conversationId,
        currentAnnouncement: currentAnnouncement,
        isOwner: _isOwner,
      ),
    ));
    if (result != null && mounted) {
      _load();
    }
  }

  // ─── Build ───

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
    final announcement = _detail!['announcement'] as String?;
    final avatar = _detail!['avatar'] as String?;

    return ListView(
      children: [
        const SizedBox(height: 10),
        // 成员网格
        _buildMemberSection(members, ownerId),
        const SizedBox(height: 10),
        // 群头像（只展示，不可修改）
        _buildSettingItem(
          title: '群头像',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGroupAvatar(avatar, 32),
              const SizedBox(width: 24),
            ],
          ),
        ),
        _buildDivider(),
        // 群聊名称
        _buildSettingItem(
          title: '群聊名称',
          value: name,
          onTap: _isOwner ? _showEditNameDialog : null,
        ),
        _buildDivider(),
        // 群号
        _buildSettingItem(title: '群号', value: groupNo.toString()),
        _buildDivider(),
        // 群公告
        _buildSettingItem(
          title: '群公告',
          value: (announcement != null && announcement.isNotEmpty) ? announcement : '未设置',
          onTap: _openAnnouncement,
        ),
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
        const SizedBox(height: 30),
        // 底部操作按钮
        if (_isOwner) ...[
          _buildActionButton('转让群主', const Color(0xFF3B82F6), _showTransferSheet),
          const SizedBox(height: 10),
          _buildActionButton('解散群聊', const Color(0xFFF44336), _confirmDisband),
        ] else
          _buildActionButton('退出群聊', const Color(0xFFF44336), _confirmLeave),
        const SizedBox(height: 40),
      ],
    );
  }

  /// 成员网格区域（含 +/- 操作按钮）
  Widget _buildMemberSection(List members, String? ownerId) {
    // 计算操作按钮数量
    final actionCount = _isOwner ? 2 : 1; // "+" 和可能的 "-"
    final maxVisible = _showAllMembers
        ? members.length
        : min(_membersPerRow * _defaultRows - actionCount, members.length);
    final visibleMembers = members.sublist(0, max(0, maxVisible));
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
                children: [
                  ...visibleMembers.map((m) {
                    final member = m as Map<String, dynamic>;
                    final userId = member['user_id']?.toString();
                    final isOwnerMember = userId == ownerId;
                    return _buildMemberTile(member, isOwnerMember, tileW);
                  }),
                  // "+" 邀请按钮
                  _buildActionTile(
                    icon: Icons.add,
                    onTap: _showInvitePage,
                    tileWidth: tileW,
                  ),
                  // "-" 踢人按钮（仅群主）
                  if (_isOwner)
                    _buildActionTile(
                      icon: Icons.remove,
                      onTap: _showRemoveSheet,
                      tileWidth: tileW,
                    ),
                ],
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

  /// 操作按钮 tile（+/-）虚线边框
  Widget _buildActionTile({
    required IconData icon,
    required VoidCallback onTap,
    required double tileWidth,
  }) {
    final avatarSize = tileWidth - 8;
    return SizedBox(
      width: tileWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: const Color(0xFFCCCCCC),
                borderRadius: avatarSize * 0.1,
              ),
              child: SizedBox(
                width: avatarSize,
                height: avatarSize,
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

  /// 操作按钮（底部）
  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 16, color: color)),
      ),
    );
  }

  /// 设置项（带箭头）
  Widget _buildSettingItem({
    required String title,
    String? value,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        child: ListTile(
          title: Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF333333))),
          trailing: trailing ?? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                color: onTap != null ? const Color(0xFFCCCCCC) : Colors.transparent,
                size: 20),
            ],
          ),
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

/// 虚线边框绘制器
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    this.borderRadius = 4,
    this.strokeWidth = 1.0,
    this.dashWidth = 4.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance = end + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color || borderRadius != oldDelegate.borderRadius;
}
