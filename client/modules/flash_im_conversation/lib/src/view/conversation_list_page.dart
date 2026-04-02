import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/conversation.dart';
import '../logic/conversation_list_cubit.dart';
import '../logic/conversation_list_state.dart';
import 'conversation_tile.dart';

/// 会话列表页面（支持下拉刷新 + 滚动加载更多）
class ConversationListPage extends StatefulWidget {
  final void Function(Conversation conversation)? onConversationTap;
  const ConversationListPage({super.key, this.onConversationTap});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ConversationListCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationListCubit, ConversationListState>(
      builder: (context, state) {
        return switch (state) {
          ConversationListInitial() => const SizedBox.shrink(),
          ConversationListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
          ConversationListError(:final message) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context
                        .read<ConversationListCubit>()
                        .loadConversations(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ConversationListLoaded(:final conversations, :final hasMore) =>
            conversations.isEmpty
                ? const Center(
                    child: Text('暂无会话',
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                  )
                : RefreshIndicator(
                    onRefresh: () => context
                        .read<ConversationListCubit>()
                        .loadConversations(),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: conversations.length + (hasMore ? 1 : 0),
                      itemBuilder: (_, index) {
                        if (index >= conversations.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        return ConversationTile(
                          conversation: conversations[index],
                          onTap: () => widget.onConversationTap?.call(conversations[index]),
                        );
                      },
                    ),
                  ),
        };
      },
    );
  }
}
