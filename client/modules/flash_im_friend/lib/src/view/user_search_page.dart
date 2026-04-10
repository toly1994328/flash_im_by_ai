import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/friend.dart';
import '../data/friend_repository.dart';

/// 用户搜索页（独立页面，从 AddFriendPage 跳转进入）
class UserSearchPage extends StatefulWidget {
  final FriendRepository repository;

  const UserSearchPage({super.key, required this.repository});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<SearchUser> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  final Set<String> _sentIds = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() { _results = []; _hasSearched = false; _isLoading = false; });
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value.trim()));
  }

  Future<void> _search(String keyword) async {
    try {
      final results = await widget.repository.searchUsers(keyword);
      if (mounted) setState(() { _results = results; _isLoading = false; _hasSearched = true; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendRequest(SearchUser user) async {
    final message = await _showMessageDialog();
    if (message == null) return;
    try {
      await widget.repository.sendRequest(user.id, message: message.isEmpty ? null : message);
      if (mounted) {
        setState(() => _sentIds.add(user.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('申请已发送'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('400') ? '已是好友' : '发送失败';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  Future<String?> _showMessageDialog() async {
    final msgController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('发送好友申请'),
        content: TextField(
          controller: msgController,
          decoration: const InputDecoration(hintText: '添加留言（可选）'),
          maxLength: 200,
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(msgController.text), child: const Text('发送')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('搜索'),
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          FlashSearchBar(
            editable: true,
            controller: _controller,
            focusNode: _focusNode,
            hintText: '闪讯号 / 手机号 / 昵称',
            onChanged: _onChanged,
            onSubmitted: (v) {
              _debounce?.cancel();
              if (v.trim().isNotEmpty) _search(v.trim());
            },
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
    if (!_hasSearched) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_outlined, size: 48, color: Color(0xFFCCCCCC)),
            SizedBox(height: 12),
            Text('输入闪讯号、手机号或昵称搜索用户', style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 48, color: Color(0xFFCCCCCC)),
            SizedBox(height: 12),
            Text('未找到用户', style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(left: 68),
        child: Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF0F0F0)),
      ),
      itemBuilder: (_, index) {
        final user = _results[index];
        final sent = _sentIds.contains(user.id);
        return InkWell(
          onTap: sent ? null : () => _sendRequest(user),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                AvatarWidget(avatar: user.avatar, size: 44, borderRadius: 6),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(user.nickname, style: const TextStyle(fontSize: 15)),
                ),
                if (sent)
                  const Text('已发送', style: TextStyle(color: Color(0xFF999999), fontSize: 13))
                else
                  const Icon(Icons.chevron_right, size: 20, color: Color(0xFFCCCCCC)),
              ],
            ),
          ),
        );
      },
    );
  }
}
