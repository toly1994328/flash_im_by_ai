import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/friend.dart';
import '../data/friend_repository.dart';
import 'user_profile_page.dart';

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
    // 全屏 loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final profile = await widget.repository.getUserProfile(user.id);
      if (!mounted) return;
      Navigator.pop(context); // 关闭 loading
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => UserProfilePage(
          profile: profile,
          repository: widget.repository,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 关闭 loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取用户信息失败: $e'), duration: const Duration(seconds: 2)),
      );
    }
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
        return InkWell(
          onTap: () => _sendRequest(user),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                AvatarWidget(avatar: user.avatar, size: 44, borderRadius: 6),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(user.nickname, style: const TextStyle(fontSize: 15)),
                ),
                const Icon(Icons.chevron_right, size: 20, color: Color(0xFFCCCCCC)),
              ],
            ),
          ),
        );
      },
    );
  }
}
