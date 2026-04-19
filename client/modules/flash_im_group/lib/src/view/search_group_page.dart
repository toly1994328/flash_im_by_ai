import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/group_repository.dart';
import '../data/group_models.dart';

/// 搜索群聊页面
///
/// 防抖搜索 + 四种按钮状态 + 入群确认/申请对话框
class SearchGroupPage extends StatefulWidget {
  final GroupRepository repository;
  final String? baseUrl;

  const SearchGroupPage({super.key, required this.repository, this.baseUrl});

  @override
  State<SearchGroupPage> createState() => _SearchGroupPageState();
}

class _SearchGroupPageState extends State<SearchGroupPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  List<GroupSearchResult> _results = [];
  bool _isLoading = false;
  String _keyword = '';
  Timer? _debounce;
  final Set<String> _joiningIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _keyword = '';
        _results = [];
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _keyword = trimmed;
      _isLoading = true;
    });
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(trimmed);
    });
  }

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final results = await widget.repository.searchGroups(keyword);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('搜索失败：$e')),
      );
    }
  }

  void _onGroupTap(GroupSearchResult group) {
    if (group.isMember || group.hasPendingRequest) return;
    _showJoinDialog(group);
  }

  void _showJoinDialog(GroupSearchResult group) {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          group.joinVerification ? '申请加入群聊' : '加入群聊',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 群信息预览
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildGroupAvatar(group, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name ?? '未命名群聊',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${group.memberCount} 人 · 群号 ${group.groupNo}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (group.joinVerification) ...[
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  hintText: '请输入申请留言（可选）',
                  hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 2,
                maxLength: 100,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消', style: TextStyle(color: Color(0xFF999999))),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _requestJoin(group, messageController.text.trim());
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(group.joinVerification ? '发送申请' : '加入'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestJoin(GroupSearchResult group, String message) async {
    if (_joiningIds.contains(group.id)) return;
    setState(() => _joiningIds.add(group.id));
    try {
      final autoApproved = await widget.repository.joinGroup(
        group.id,
        message: message.isNotEmpty ? message : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(autoApproved ? '已成功加入群聊' : '申请已发送，等待群主审批')),
      );
      _search(_keyword);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _joiningIds.remove(group.id));
    }
  }

  Widget _buildGroupAvatar(GroupSearchResult group, {double size = 44}) {
    final avatar = _resolveUrl(group.avatar);
    if (avatar != null && avatar.startsWith('grid:')) {
      final avatarList = avatar.substring(5).split(',');
      final members = <GroupAvatarMember>[];
      for (var i = 0; i < avatarList.length; i++) {
        final a = avatarList[i].trim();
        members.add(GroupAvatarMember(id: 'member_$i', avatarUrl: a.isNotEmpty ? a : null));
      }
      return GroupAvatarWidget(members: members, size: size, borderRadius: 6);
    }
    return AvatarWidget(avatar: avatar, size: size);
  }

  String? _resolveUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http') || path.startsWith('grid:')) return path;
    if (widget.baseUrl != null) return '${widget.baseUrl}$path';
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('搜索群聊'),
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // 搜索栏 + 右侧 loading 指示器
          Container(
            color: const Color(0xFFEDEDED),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  const Icon(Icons.search, size: 18, color: Color(0xFF999999)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: _onChanged,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: '群名 / 群号',
                        hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_keyword.isEmpty) {
      return _buildHint(Icons.groups_outlined, '输入群名或群号搜索');
    }
    if (_results.isEmpty && !_isLoading) {
      return _buildHint(Icons.search_off_outlined, '未找到相关群聊');
    }
    if (_results.isEmpty && _isLoading) {
      return const SizedBox.shrink();
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) => _buildItem(_results[index]),
    );
  }

  Widget _buildHint(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: const Color(0xFFCCCCCC)),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildItem(GroupSearchResult group) {
    return InkWell(
      onTap: () => _onGroupTap(group),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5)),
        ),
        child: Row(
          children: [
            _buildGroupAvatar(group),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name ?? '未命名群聊',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${group.memberCount} 人 · 群号 ${group.groupNo}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildActionButton(group),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(GroupSearchResult group) {
    if (group.isMember) {
      return _tag('已加入', const Color(0xFFF0F0F0), const Color(0xFF999999));
    }
    if (group.hasPendingRequest) {
      return _tag('已申请', const Color(0xFFF0F0F0), const Color(0xFF999999));
    }
    if (_joiningIds.contains(group.id)) {
      return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (group.joinVerification) {
      return _outlineTag('申请', const Color(0xFFFF9800));
    }
    return _filledTag('加入', const Color(0xFF3B82F6));
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 12, color: fg)),
    );
  }

  Widget _outlineTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: color)),
    );
  }

  Widget _filledTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
    );
  }
}
