import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../data/conversation.dart';
import '../logic/conversation_list_cubit.dart';
import '../logic/conversation_list_state.dart';
import 'conversation_tile.dart';

/// 会话列表页面（置顶分区 + 普通分区，支持下拉刷新 + 滚动加载更多）
class ConversationListPage extends StatefulWidget {
  final void Function(Conversation conversation)? onConversationTap;
  final Set<String> onlineUserIds;
  final String? activeConversationId;
  const ConversationListPage({super.key, this.onConversationTap, this.onlineUserIds = const {}, this.activeConversationId});

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

  List<Conversation> _pinned(List<Conversation> list) =>
      list.where((c) => c.isPinned).toList();

  List<Conversation> _normal(List<Conversation> list) =>
      list.where((c) => !c.isPinned).toList();

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
                  Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    message.contains('connection') || message.contains('SocketException')
                        ? '网络连接失败，请检查网络'
                        : '加载失败',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 12),
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
                : _buildLoadedList(context, conversations, hasMore),
        };
      },
    );
  }

  Widget _buildLoadedList(
    BuildContext context,
    List<Conversation> conversations,
    bool hasMore,
  ) {
    final pinned = _pinned(conversations);
    final normal = _normal(conversations);
    final cubit = context.read<ConversationListCubit>();

    // 构建一个带 section 的列表
    final items = <_SectionItem>[];
    if (pinned.isNotEmpty) {
      items.add(const _SectionHeader('置顶'));
      for (final conv in pinned) {
        items.add(_ConvItem(conv));
      }
    }
    if (normal.isNotEmpty) {
      if (pinned.isNotEmpty) {
        items.add(const _SectionDivider());
      }
      for (final conv in normal) {
        items.add(_ConvItem(conv));
      }
    }

    final totalCount = items.length + (hasMore ? 1 : 0);

    return SlidableAutoCloseBehavior(
      child: RefreshIndicator(
        onRefresh: () => cubit.loadConversations(),
        child: ListView.builder(
        controller: _scrollController,
        itemCount: totalCount,
        itemBuilder: (_, index) {
          if (index >= items.length) {
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

          final item = items[index];
          return switch (item) {
            _SectionHeader(:final label) => _buildSectionHeader(label),
            _ConvItem(:final conv) => _buildConversationTile(context, conv, cubit),
            _SectionDivider() => _buildDivider(),
          };
        },
      ),
    ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFFF7F7F7),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF999999),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const ColoredBox(
      color: Color(0xFFF5F5F5),
      child: SizedBox(height: 8),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    Conversation conv,
    ConversationListCubit cubit,
  ) {
    final mentionRecords = cubit.getMentionMeRecords(conv.id);
    final displayConv = mentionRecords.isNotEmpty
        ? Conversation(
            id: conv.id, type: conv.type, name: conv.name,
            avatar: conv.avatar, peerUserId: conv.peerUserId,
            peerNickname: conv.peerNickname, peerAvatar: conv.peerAvatar,
            lastMessageAt: conv.lastMessageAt,
            lastMessagePreview: conv.lastMessagePreview,
            lastMessageExtra: conv.lastMessageExtra,
            mentionMeRecords: mentionRecords,
            unreadCount: conv.unreadCount,
            isPinned: conv.isPinned, isMuted: conv.isMuted,
            pinnedAt: conv.pinnedAt,
            createdAt: conv.createdAt,
          )
        : conv;

    return ConversationTile(
      conversation: displayConv,
      isOnline: !conv.isGroup &&
          conv.peerUserId != null &&
          widget.onlineUserIds.contains(conv.peerUserId),
      isActive: widget.activeConversationId == conv.id,
      onTap: () => widget.onConversationTap?.call(conv),
      onTogglePin: (id) => cubit.togglePin(id),
      onToggleMute: (id) => cubit.toggleMute(id),
      onMarkRead: (id) => cubit.clearUnread(id),
      onMarkUnread: (id) => cubit.markUnread(id),
      onDelete: (id) => cubit.deleteConversation(id),
      onClearAll: (id) => cubit.clearMessages(id),
    );
  }
}

// ─── 内部类型标记 ───

sealed class _SectionItem {
  const _SectionItem();
}
class _SectionHeader extends _SectionItem {
  final String label;
  const _SectionHeader(this.label);
}
class _ConvItem extends _SectionItem {
  final Conversation conv;
  const _ConvItem(this.conv);
}
class _SectionDivider extends _SectionItem {
  const _SectionDivider();
}
