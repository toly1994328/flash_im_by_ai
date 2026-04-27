import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/search_models.dart';
import '../data/search_repository.dart';
import 'widgets/highlight_text.dart';
import 'single_message_page.dart';

/// 会话内搜索页
///
/// 在指定会话中搜索消息，支持 300ms 防抖。
class ConversationSearchPage extends StatefulWidget {
  final String conversationId;
  final String conversationName;
  final SearchRepository repository;
  final void Function(String conversationId, String? messageId)? onMessageTap;

  const ConversationSearchPage({
    super.key,
    required this.conversationId,
    required this.conversationName,
    required this.repository,
    this.onMessageTap,
  });

  @override
  State<ConversationSearchPage> createState() => _ConversationSearchPageState();
}

class _ConversationSearchPageState extends State<ConversationSearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;

  List<MessageSearchItem>? _results;
  bool _isLoading = false;
  String _currentKeyword = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = null;
        _isLoading = false;
        _currentKeyword = '';
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _doSearch(trimmed);
    });
  }

  Future<void> _doSearch(String keyword) async {
    setState(() {
      _isLoading = true;
      _currentKeyword = keyword;
    });
    try {
      final results = await widget.repository.searchConversationMessages(
        conversationId: widget.conversationId,
        keyword: keyword,
      );
      if (mounted && _currentKeyword == keyword) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
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
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: const BackButton(color: Color(0xFF333333)),
        title: FlashSearchInput(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          hintText: '搜索 ${widget.conversationName}',
          backgroundColor: const Color(0xFFF5F5F5),
        ),
        actions: const [SizedBox(width: 12)],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results == null) {
      return const SizedBox.shrink();
    }

    if (_results!.isEmpty) {
      return const Center(
        child: Text(
          '无搜索结果',
          style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
        ),
      );
    }

    return ListView.separated(
      itemCount: _results!.length,
      separatorBuilder: (_, __) => const Divider(
        height: 0.5,
        thickness: 0.5,
        color: Color(0xFFE8E8E8),
        indent: 68,
      ),
      itemBuilder: (context, index) {
        final msg = _results![index];
        return _ConversationMessageTile(
          message: msg,
          keyword: _currentKeyword,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SingleMessagePage(
                message: msg,
                keyword: _currentKeyword,
              ),
            ));
          },
        );
      },
    );
  }
}

class _ConversationMessageTile extends StatelessWidget {
  final MessageSearchItem message;
  final String keyword;
  final VoidCallback? onTap;

  const _ConversationMessageTile({
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
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.seq != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                '#${message.seq}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFBBBBBB),
                                ),
                              ),
                            ),
                          Text(
                            _formatTime(message.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  HighlightText(
                    text: message.content,
                    keyword: keyword,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                    highlightStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF3B82F6),
                    ),
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
    if (time.year == now.year) {
      return '${time.month}/${time.day}';
    }
    return '${time.year}/${time.month}/${time.day}';
  }
}
