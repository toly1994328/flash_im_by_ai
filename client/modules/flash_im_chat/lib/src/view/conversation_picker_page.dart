import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// 会话选择器：转发时选择目标会话
class ConversationPickerPage extends StatefulWidget {
  final String? excludeConvId;
  final Dio dio;
  final String? baseUrl;

  const ConversationPickerPage({
    super.key,
    this.excludeConvId,
    required this.dio,
    this.baseUrl,
  });

  @override
  State<ConversationPickerPage> createState() => _ConversationPickerPageState();
}

class _ConversationPickerPageState extends State<ConversationPickerPage> {
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final res = await widget.dio.get('/conversations', queryParameters: {'limit': 100});
      final List data = res.data as List;
      setState(() {
        _conversations = data
            .cast<Map<String, dynamic>>()
            .where((c) => c['id'] != widget.excludeConvId)
            .toList();
        _filtered = _conversations;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = _conversations;
      } else {
        _filtered = _conversations.where((c) {
          final name = (c['name'] ?? c['peer_nickname'] ?? '').toString().toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择会话', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // 搜索栏
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索',
                hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFBBBBBB), size: 20),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // 列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('无会话', style: TextStyle(color: Color(0xFF999999))))
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Padding(
                          padding: EdgeInsets.only(left: 68),
                          child: Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF0F0F0)),
                        ),
                        itemBuilder: (_, index) {
                          final conv = _filtered[index];
                          return _buildConvTile(conv);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildConvTile(Map<String, dynamic> conv) {
    final name = conv['name'] ?? conv['peer_nickname'] ?? '未知';
    final isGroup = conv['conv_type'] == 1;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isGroup ? const Color(0xFF4CAF50) : const Color(0xFF3B82F6),
        child: Icon(
          isGroup ? Icons.group : Icons.person,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(name, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
      subtitle: Text(
        isGroup ? '群聊' : '私聊',
        style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
      ),
      onTap: () => _confirmAndReturn(conv),
    );
  }

  void _confirmAndReturn(Map<String, dynamic> conv) {
    final name = conv['name'] ?? conv['peer_nickname'] ?? '未知';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('转发给 $name？', style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消', style: TextStyle(color: Color(0xFF999999))),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(conv['id'] as String);
            },
            child: const Text('确认', style: TextStyle(color: Color(0xFF3B82F6))),
          ),
        ],
      ),
    );
  }
}
