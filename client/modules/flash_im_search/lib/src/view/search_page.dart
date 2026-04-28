import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/search_models.dart';
import '../data/search_repository.dart';
import '../logic/search_cubit.dart';
import '../logic/search_state.dart';
import 'widgets/friend_search_item.dart';
import 'widgets/group_search_item.dart';
import 'widgets/message_search_item.dart';
import 'message_detail_page.dart';

/// 综合搜索页
class SearchPage extends StatelessWidget {
  final SearchRepository repository;
  final void Function(String friendId)? onFriendTap;
  final void Function(String conversationId)? onGroupTap;
  final void Function(String conversationId, String? messageId)? onMessageTap;

  const SearchPage({
    super.key,
    required this.repository,
    this.onFriendTap,
    this.onGroupTap,
    this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchCubit(repository),
      child: _SearchView(
        onFriendTap: onFriendTap,
        onGroupTap: onGroupTap,
        onMessageTap: onMessageTap,
        repository: repository,
      ),
    );
  }
}

class _SearchView extends StatefulWidget {
  final void Function(String friendId)? onFriendTap;
  final void Function(String conversationId)? onGroupTap;
  final void Function(String conversationId, String? messageId)? onMessageTap;
  final SearchRepository repository;

  const _SearchView({
    this.onFriendTap,
    this.onGroupTap,
    this.onMessageTap,
    required this.repository,
  });

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  static const _historyKey = 'im_search_history';
  static const _maxHistory = 20;
  List<String> _history = [];

  // 各分区是否展开
  bool _friendExpanded = false;
  bool _groupExpanded = false;
  bool _messageExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList(_historyKey) ?? [];
    });
  }

  Future<void> _saveKeyword(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    _history.remove(trimmed);
    _history.insert(0, trimmed);
    if (_history.length > _maxHistory) {
      _history = _history.sublist(0, _maxHistory);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, _history);
    if (mounted) setState(() {});
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    setState(() => _history = []);
  }

  void _onSearch(String keyword) {
    context.read<SearchCubit>().search(keyword);
    if (keyword.trim().isNotEmpty) {
      _saveKeyword(keyword);
    }
    setState(() {
      _friendExpanded = false;
      _groupExpanded = false;
      _messageExpanded = false;
    });
  }

  void _onHistoryTap(String keyword) {
    _controller.text = keyword;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: keyword.length),
    );
    _onSearch(keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: FlashSearchInput(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onSearch,
            backgroundColor: const Color(0xFFF5F5F5),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '取消',
                style: TextStyle(fontSize: 15, color: Color(0xFF3B82F6)),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          return switch (state) {
            SearchInitial() => _buildHistoryView(),
            SearchLoading() => const Center(child: CircularProgressIndicator()),
            SearchSuccess(result: final result) => _buildResultView(result),
            SearchPartialSuccess(result: final result) => _buildResultView(result),
          };
        },
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_history.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最近在搜',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
              ),
              GestureDetector(
                onTap: _clearHistory,
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _history.map((keyword) {
              return GestureDetector(
                onTap: () => _onHistoryTap(keyword),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    keyword,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(SearchResult result) {
    if (!result.hasAnyResult) {
      return const Center(
        child: Text(
          '无搜索结果',
          style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
        ),
      );
    }

    final keyword = _controller.text.trim();

    return ListView(
      children: [
        if (result.friends.isNotEmpty)
          _buildFriendSection(result.friends, keyword),
        if (result.groups.isNotEmpty)
          _buildGroupSection(result.groups, keyword),
        if (result.messageGroups.isNotEmpty)
          _buildMessageSection(result.messageGroups, keyword),
      ],
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        '$title($count)',
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF999999),
        ),
      ),
    );
  }

  Widget _buildShowMore(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF576B95)),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 0.5,
      thickness: 0.5,
      color: Color(0xFFE8E8E8),
      indent: 68,
    );
  }

  Widget _buildFriendSection(List<FriendSearchItem> friends, String keyword) {
    final displayCount = _friendExpanded ? friends.length : 3;
    final items = friends.take(displayCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('联系人', friends.length),
        ...items.map((item) => Column(
              children: [
                FriendSearchItemWidget(
                  item: item,
                  keyword: keyword,
                  onTap: () => widget.onFriendTap?.call(item.friendId),
                ),
                _buildDivider(),
              ],
            )),
        if (!_friendExpanded && friends.length > 3)
          _buildShowMore('更多联系人', () => setState(() => _friendExpanded = true)),
      ],
    );
  }

  Widget _buildGroupSection(List<GroupSearchItem> groups, String keyword) {
    final displayCount = _groupExpanded ? groups.length : 3;
    final items = groups.take(displayCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('群聊', groups.length),
        ...items.map((item) => Column(
              children: [
                GroupSearchItemWidget(
                  item: item,
                  keyword: keyword,
                  onTap: () => widget.onGroupTap?.call(item.conversationId),
                ),
                _buildDivider(),
              ],
            )),
        if (!_groupExpanded && groups.length > 3)
          _buildShowMore('更多群聊', () => setState(() => _groupExpanded = true)),
      ],
    );
  }

  Widget _buildMessageSection(
    List<MessageSearchGroup> messageGroups,
    String keyword,
  ) {
    final displayCount = _messageExpanded ? messageGroups.length : 3;
    final items = messageGroups.take(displayCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('聊天记录', messageGroups.length),
        ...items.map((group) => Column(
              children: [
                MessageSearchItemWidget(
                  group: group,
                  keyword: keyword,
                  onTap: () => _onMessageGroupTap(group, keyword),
                ),
                _buildDivider(),
              ],
            )),
        if (!_messageExpanded && messageGroups.length > 3)
          _buildShowMore('更多消息', () => setState(() => _messageExpanded = true)),
      ],
    );
  }

  void _onMessageGroupTap(MessageSearchGroup group, String keyword) {
    // 只有一条匹配消息时直接跳转
    if (group.matchCount == 1 && group.messages.length == 1) {
      widget.onMessageTap?.call(
        group.conversationId,
        group.messages.first.messageId,
      );
      return;
    }
    // 多条匹配消息时进入详情页
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MessageDetailPage(
          group: group,
          keyword: keyword,
          repository: widget.repository,
          onMessageTap: widget.onMessageTap,
        ),
      ),
    );
  }
}
