import 'dart:async';
import 'package:flutter/material.dart';
import '../data/conversation_repository.dart';
import '../data/group_models.dart';

/// 搜索群聊页面
class SearchGroupPage extends StatefulWidget {
  final ConversationRepository repository;

  const SearchGroupPage({super.key, required this.repository});

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
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(trimmed));
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
    }
  }

  void _onGroupTap(GroupSearchResult group) {
    if (group.isMember) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('你已经是该群成员')),
      );
      return;
    }
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.group, color: Color(0xFF999999), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name ?? '未命名群聊',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text('${group.memberCount} 人',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
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
                  counterStyle: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
                ),
                maxLines: 2,
                maxLength: 100,
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
      final response = await widget.repository.requestJoin(
        group.id,
        message: message.isNotEmpty ? message : null,
      );
      if (!mounted) return;
      if (response.autoApproved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已成功加入群聊')),
        );
        _search(_searchController.text);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('申请已发送，等待群主审批')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: '搜索群聊名称',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Color(0xFF999999)),
          ),
        ),
        actions: [
          if (_keyword.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                _searchController.clear();
                _onChanged('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_keyword.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 48, color: Color(0xFFCCCCCC)),
            SizedBox(height: 12),
            Text('输入群名称搜索', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
          ],
        ),
      );
    }
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_outlined, size: 48, color: Color(0xFFCCCCCC)),
            SizedBox(height: 12),
            Text('未找到相关群聊', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final group = _results[index];
        return _buildGroupItem(group);
      },
    );
  }

  Widget _buildGroupItem(GroupSearchResult group) {
    return InkWell(
      onTap: () => _onGroupTap(group),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.group, color: Color(0xFF999999), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name ?? '未命名群聊',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('${group.memberCount} 人',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
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
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('已加入', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
      );
    }
    if (_joiningIds.contains(group.id)) {
      return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (group.joinVerification) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF576B95)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('申请加入', style: TextStyle(fontSize: 12, color: Color(0xFF576B95))),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF576B95),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('加入', style: TextStyle(fontSize: 12, color: Colors.white)),
    );
  }
}
