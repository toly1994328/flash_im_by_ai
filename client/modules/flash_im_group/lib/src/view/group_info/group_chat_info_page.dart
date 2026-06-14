import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_shared/flash_shared.dart';

import '../../data/group_detail.dart';
import '../../data/group_repository.dart';
import '../../logic/group_info_cubit.dart';
import '../create_group_page.dart';
import '../edit_group_name_page.dart';
import '../group_announcement_page.dart';
import 'group_action_section.dart';
import 'group_member_grid.dart';
import 'group_setting_widgets.dart';

/// 群聊详情页。
///
/// ## 页面结构
///
/// ```
/// ┌─────────────────────────────┐
/// │  AppBar                     │
/// ├─────────────────────────────┤
/// │  GroupMemberGrid            │  成员网格（+/- 操作）
/// ├─────────────────────────────┤
/// │  SettingSection             │  群头像/群名/群号/公告/搜索
/// ├─────────────────────────────┤
/// │  SwitchItem (群主)          │  入群验证
/// ├─────────────────────────────┤
/// │  GroupActionSection         │  转让/解散/退出
/// └─────────────────────────────┘
/// ```
///
/// ## 状态来源
///
/// - [GroupInfoCubit] — 群详情加载与操作
class GroupChatInfoPage extends StatelessWidget {
  final GroupRepository repository;
  final String conversationId;
  final String? baseUrl;
  final String? currentUserId;
  final Future<List<SelectableMember>> Function()? friendsFetcher;
  final VoidCallback? onLeaveOrDisband;
  final VoidCallback? onSearchChat;
  final bool showAppBar;

  const GroupChatInfoPage({
    super.key,
    required this.repository,
    required this.conversationId,
    this.baseUrl,
    this.currentUserId,
    this.friendsFetcher,
    this.onLeaveOrDisband,
    this.onSearchChat,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: showAppBar ? const Color(0xFFF5F5F5) : Colors.white,
      appBar: showAppBar
          ? AppBar(
              title: const Text('群聊信息'),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF333333),
              elevation: 0,
              scrolledUnderElevation: 0,
            )
          : null,
      body: BlocBuilder<GroupInfoCubit, GroupInfoState>(
        builder: (context, state) => switch (state) {
          GroupInfoLoading() => const Center(child: CircularProgressIndicator()),
          GroupInfoError(:final message) => _ErrorView(message: message, onRetry: () => context.read<GroupInfoCubit>().loadDetail()),
          GroupInfoLoaded(:final detail) => _DetailView(
            detail: detail,
            baseUrl: baseUrl,
            currentUserId: currentUserId,
            friendsFetcher: friendsFetcher,
            onLeaveOrDisband: onLeaveOrDisband,
            onSearchChat: onSearchChat,
            showAppBar: showAppBar,
          ),
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('加载失败', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  final GroupDetail detail;
  final String? baseUrl;
  final String? currentUserId;
  final Future<List<SelectableMember>> Function()? friendsFetcher;
  final VoidCallback? onLeaveOrDisband;
  final VoidCallback? onSearchChat;
  final bool showAppBar;

  const _DetailView({
    required this.detail,
    this.baseUrl,
    this.currentUserId,
    this.friendsFetcher,
    this.onLeaveOrDisband,
    this.onSearchChat,
    required this.showAppBar,
  });

  bool get _isOwner => currentUserId != null && detail.ownerId == currentUserId;

  String? _resolveUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http') || path.startsWith('identicon:') || path.startsWith('grid:')) return path;
    if (baseUrl != null) return '$baseUrl$path';
    return path;
  }

  Widget _buildGroupAvatar(String? avatar, double size) {
    final String? resolved = _resolveUrl(avatar);
    if (resolved != null && resolved.startsWith('grid:')) {
      final List<String> avatarList = resolved.substring(5).split(',');
      final List<GroupAvatarMember> members = avatarList.asMap().entries.map((e) =>
        GroupAvatarMember(id: 'member_${e.key}', avatarUrl: e.value.trim().isNotEmpty ? e.value.trim() : null),
      ).toList();
      return GroupAvatarWidget(members: members, size: size, borderRadius: 4);
    }
    return AvatarWidget(avatar: resolved, size: size, borderRadius: 4);
  }

  @override
  Widget build(BuildContext context) {
    final GroupInfoCubit cubit = context.read<GroupInfoCubit>();

    return ListView(
      children: [
        if (showAppBar) const SizedBox(height: 10),
        GroupMemberGrid(
          members: detail.members,
          ownerId: detail.ownerId,
          isOwner: _isOwner,
          baseUrl: baseUrl,
          onInvite: () => _showInvitePage(context, cubit),
          onRemove: _isOwner ? () => _showRemoveSheet(context, cubit) : null,
        ),
        const SizedBox(height: 10),
        SettingItem(
          title: '群头像',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            _buildGroupAvatar(detail.avatar, 32),
            const SizedBox(width: 24),
          ]),
        ),
        const SettingDivider(),
        SettingItem(
          title: '群聊名称',
          value: detail.name,
          onTap: _isOwner ? () => _showEditNameDialog(context, cubit) : null,
        ),
        const SettingDivider(),
        SettingItem(title: '群号', value: detail.groupNo.toString()),
        const SettingDivider(),
        SettingItem(
          title: '群公告',
          value: (detail.announcement?.isNotEmpty == true) ? detail.announcement : '未设置',
          onTap: () => _openAnnouncement(context, cubit),
        ),
        const SizedBox(height: 10),
        SettingItem(title: '查找聊天内容', onTap: onSearchChat),
        if (_isOwner) ...[
          const SizedBox(height: 10),
          SwitchItem(
            title: '入群验证',
            subtitle: '开启后，新成员需要群主审批才能加入',
            value: detail.joinVerification,
            onChanged: (value) => cubit.toggleJoinVerification(value),
          ),
        ],
        GroupActionSection(
          isOwner: _isOwner,
          onTransfer: () => _showTransferSheet(context, cubit),
          onDisband: () => _confirmDisband(context, cubit),
          onLeave: () => _confirmLeave(context, cubit),
        ),
      ],
    );
  }

  // ─── 页面跳转 & 确认弹窗 ───

  void _showInvitePage(BuildContext context, GroupInfoCubit cubit) async {
    if (friendsFetcher == null) return;
    try {
      final List<SelectableMember> friends = await friendsFetcher!();
      if (!context.mounted) return;
      final Set<String> existingIds = detail.members.map((m) => m.userId).toSet();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CreateGroupPage(
          members: friends,
          initialSelectedIds: existingIds,
          onCreated: (result) async {
            final List<int> newIds = result.memberIds.where((id) => !existingIds.contains(id.toString())).toList();
            if (newIds.isEmpty) { Navigator.of(context).pop(); return; }
            final int count = await cubit.inviteMembers(newIds);
            if (context.mounted) {
              Navigator.of(context).pop();
              if (count > 0) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功邀请 $count 人入群')));
              }
            }
          },
        ),
      ));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('获取好友列表失败：$e')));
      }
    }
  }

  void _showRemoveSheet(BuildContext context, GroupInfoCubit cubit) {
    final List<GroupMember> removable = detail.members.where((m) => m.userId != detail.ownerId).toList();
    if (removable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('没有可移除的成员')));
      return;
    }
    final List<SelectableMember> selectableMembers = removable.map((m) => SelectableMember(
      id: m.userId,
      nickname: m.nickname,
      avatar: _resolveUrl(m.avatar),
      letter: PinyinUtil.getFirstLetter(m.nickname),
    )).toList();

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MemberPickerPage(
        members: selectableMembers,
        title: '移除成员',
        confirmLabel: '移除',
        isRemoveMode: true,
        onConfirm: (result) async {
          Navigator.of(context).pop();
          await cubit.removeMembers(result.newIds);
        },
      ),
    ));
  }

  void _showTransferSheet(BuildContext context, GroupInfoCubit cubit) {
    final List<GroupMember> transferable = detail.members.where((m) => m.userId != currentUserId).toList();
    if (transferable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('没有可转让的成员')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5, maxChildSize: 0.8, minChildSize: 0.3, expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('转让群主', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
            ),
            const Divider(height: 0.5),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: transferable.length,
                itemBuilder: (_, index) {
                  final GroupMember member = transferable[index];
                  return ListTile(
                    leading: AvatarWidget(avatar: _resolveUrl(member.avatar), size: 40, borderRadius: 6),
                    title: Text(member.nickname, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _confirmTransfer(context, cubit, member);
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

  Future<void> _confirmTransfer(BuildContext context, GroupInfoCubit cubit, GroupMember member) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('转让群主'),
        content: Text('确定将群主转让给 ${member.nickname}？转让后你将变为普通成员。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消', style: TextStyle(color: Color(0xFF999999)))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('确定', style: TextStyle(color: Color(0xFF3B82F6)))),
        ],
      ),
    );
    if (confirmed != true) return;
    await cubit.transferOwner(int.parse(member.userId), member.nickname);
  }

  Future<void> _confirmDisband(BuildContext context, GroupInfoCubit cubit) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('解散群聊'),
        content: const Text('解散后，所有群成员将被移出，且无法恢复。确定解散？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消', style: TextStyle(color: Color(0xFF999999)))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('解散', style: TextStyle(color: Color(0xFFF44336)))),
        ],
      ),
    );
    if (confirmed != true) return;
    await cubit.disbandGroup();
    if (context.mounted) onLeaveOrDisband?.call();
  }

  Future<void> _confirmLeave(BuildContext context, GroupInfoCubit cubit) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('退出群聊'),
        content: const Text('退出后将不再接收此群聊消息，确定退出？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消', style: TextStyle(color: Color(0xFF999999)))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('退出', style: TextStyle(color: Color(0xFFF44336)))),
        ],
      ),
    );
    if (confirmed != true) return;
    await cubit.leaveGroup();
    if (context.mounted) onLeaveOrDisband?.call();
  }

  Future<void> _showEditNameDialog(BuildContext context, GroupInfoCubit cubit) async {
    final String? newName = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => EditGroupNamePage(currentName: detail.name, avatar: _resolveUrl(detail.avatar)),
    ));
    if (newName == null || newName.isEmpty || newName == detail.name) return;
    await cubit.updateGroupName(newName);
  }

  void _openAnnouncement(BuildContext context, GroupInfoCubit cubit) async {
    final String? result = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => GroupAnnouncementPage(
        repository: cubit.repository,
        conversationId: cubit.conversationId,
        currentAnnouncement: detail.announcement,
        isOwner: _isOwner,
      ),
    ));
    if (result != null && context.mounted) cubit.loadDetail();
  }
}
