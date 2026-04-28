import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/search_models.dart';
import '../data/search_repository.dart';
import 'widgets/highlight_text.dart';

/// 消息搜索详情页
///
/// 展示某个会话中所有匹配的消息列表，支持分页加载。
class MessageDetailPage extends StatefulWidget {
  final MessageSearchGroup group;
  final String keyword;
  final SearchRepository repository;
  final void Function(String conversationId, String? messageId)? onMessageTap;

  const MessageDetailPage({
    super.key,
    required this.group,
    required this.keyword,
    required this.repository,
    this.onMessageTap,
  });

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  final _scrollController = ScrollController();
  final List<MessageSearchItem> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMessages() async {
    try {
      final results = await widget.repository.searchConversationMessages(
        conversationId: widget.group.conversationId,
        keyword: widget.keyword,
        limit: _pageSize,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _messages.addAll(results);
          _isLoading = false;
          _hasMore = results.length >= _pageSize;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    try {
      final results = await widget.repository.searchConversationMessages(
        conversationId: widget.group.conversationId,
        keyword: widget.keyword,
        limit: _pageSize,
        offset: _messages.length,
      );
      if (mounted) {
        setState(() {
          _messages.addAll(results);
          _hasMore = results.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.group.conversationName,
          style: const TextStyle(fontSize: 17, color: Color(0xFF333333)),
        ),
        leading: const BackButton(color: Color(0xFF333333)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? const Center(
                  child: Text('无匹配消息',
                      style: TextStyle(fontSize: 14, color: Color(0xFF999999))))
              : ListView.separated(
                  controller: _scrollController,
                  itemCount: _messages.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(
                    height: 0.5, thickness: 0.5,
                    color: Color(0xFFE8E8E8), indent: 68,
                  ),
                  itemBuilder: (context, index) {
                    if (index >= _messages.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )),
                      );
                    }
                    final msg = _messages[index];
                    return _MessageTile(
                      message: msg,
                      keyword: widget.keyword,
                      onTap: () => widget.onMessageTap?.call(
                        widget.group.conversationId,
                        msg.messageId,
                      ),
                    );
                  },
                ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final MessageSearchItem message;
  final String keyword;
  final VoidCallback? onTap;

  const _MessageTile({
    required this.message,
    required this.keyword,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarWidget(avatar: message.senderAvatar, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          message.senderName,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF333333)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(message.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF999999)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  HighlightText(
                    text: message.content,
                    keyword: keyword,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF999999)),
                    highlightStyle: const TextStyle(
                        fontSize: 13, color: Color(0xFF3B82F6)),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);
    if (date == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    if (date == today.subtract(const Duration(days: 1))) {
      return '昨天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    if (time.year == now.year) return '${time.month}/${time.day}';
    return '${time.year}/${time.month}/${time.day}';
  }
}
