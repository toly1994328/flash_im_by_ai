import 'package:flash_shared/flash_shared.dart';
import 'package:flutter/material.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';
import '../data/group_models.dart';

/// 我的群聊页面
///
/// 顶部搜索栏 → 我已加入的群聊列表，搜索只过滤本地已加入的群。
class MyGroupsPage extends StatefulWidget {
  final ConversationRepository repository;
  final void Function(Conversation conversation)? onGroupTap;

  const MyGroupsPage({
    super.key,
    required this.repository,
    this.onGroupTap,
  });

  @override
  State<MyGroupsPage> createState() => _MyGroupsPageState();
}

class _MyGroupsPageState extends State<MyGroupsPage> {
  List<Conversation> _myGroups = [];
  bool _isLoading = true;
  String _keyword = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMyGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMyGroups() async {
    setState(() => _isLoading = true);
    try {
      final groups = await widget.repository.getList(type: 1, limit: 200);
      if (!mounted) return;
      setState(() {
        _myGroups = groups;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _keyword = value.trim());
  }

  List<Conversation> get _filteredGroups {
    if (_keyword.isEmpty) return _myGroups;
    final kw = _keyword.toLowerCase();
    return _myGroups.where((g) =>
      (g.name ?? '').toLowerCase().contains(kw) ||
      g.displayName.toLowerCase().contains(kw)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('群聊'),
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          FlashSearchBar(
            editable: true,
            controller: _searchController,
            onChanged: _onSearchChanged,
            hintText: '搜索',
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final groups = _filteredGroups;

    if (_myGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 48, color: Color(0xFFCCCCCC)),
            SizedBox(height: 12),
            Text('暂无群聊', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
          ],
        ),
      );
    }

    if (_keyword.isNotEmpty && groups.isEmpty) {
      return const Center(
        child: Text('未找到相关群聊', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyGroups,
      child: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (_, index) => _buildGroupTile(groups[index]),
      ),
    );
  }

  Widget _buildGroupTile(Conversation group) {
    final avatar = group.displayAvatar;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => widget.onGroupTap?.call(group),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildGroupAvatar(avatar),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  group.displayName,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(String? avatar) {
    if (avatar != null && avatar.startsWith('grid:')) {
      final avatarList = avatar.substring(5).split(',');
      final members = avatarList.asMap().entries.map((e) =>
        GroupAvatarMember(id: 'g_${e.key}', avatarUrl: e.value.trim().isNotEmpty ? e.value.trim() : null),
      ).toList();
      return GroupAvatarWidget(members: members, size: 44, borderRadius: 6);
    }
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.group, color: Colors.white, size: 24),
    );
  }
}
