import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../logic/chat_cubit.dart';
import '../logic/chat_state.dart';
import 'message_bubble.dart';
import 'chat_input.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String peerName;
  final String? peerAvatar;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.peerName,
    this.peerAvatar,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
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
    // reverse 列表：position.pixels 接近 maxScrollExtent 时是往上滚（加载历史）
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ChatCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                return switch (state) {
                  ChatInitial() => const SizedBox.shrink(),
                  ChatLoading() => _buildSkeleton(),
                  ChatError(:final message) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(message, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.read<ChatCubit>().loadMessages(),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                  ChatLoaded(:final messages, :final hasMore, :final isLoadingMore) =>
                    messages.isEmpty
                      ? const Center(child: Text('暂无消息', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          itemCount: messages.length + (hasMore ? 1 : 0),
                          itemBuilder: (_, index) {
                            if (index >= messages.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )),
                              );
                            }
                            // reverse 列表：index 0 是最新消息
                            final msg = messages[messages.length - 1 - index];
                            final isMe = msg.senderId == context.read<ChatCubit>().currentUserId;
                            return MessageBubble(message: msg, isMe: isMe);
                          },
                        ),
                };
              },
            ),
          ),
          ChatInput(
            onSend: (content) => context.read<ChatCubit>().sendMessage(content),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        reverse: true,
        itemCount: 8,
        itemBuilder: (_, index) {
          final isMe = index % 3 == 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Container(
                  width: 120 + (index % 3) * 40,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
