import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_shared/flash_shared.dart';
import 'package:flash_im_core/flash_im_core.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';
import 'package:flash_im_chat/flash_im_chat.dart';
import 'package:flash_im_friend/flash_im_friend.dart';
import 'package:flash_im_group/flash_im_group.dart';
import 'package:flash_im_search/flash_im_search.dart';
import '../../application/config.dart';

/// 公共动作 mixin：移动端和桌面端共用的业务操作
mixin HomeActionsMixin<T extends StatefulWidget> on State<T> {
  ConversationListCubit get convCubit;

  List<SelectableMember> friendsToMembers() {
    return context.read<FriendCubit>().state.friends
        .map((f) => SelectableMember(
              id: f.friendId,
              nickname: f.nickname,
              avatar: f.avatar,
              letter: PinyinUtil.getFirstLetter(f.nickname),
            ))
        .toList();
  }

  /// 打开聊天（全屏 push，移动端使用）
  Future<void> openChat(BuildContext ctx, Conversation conversation) async {
    final session = ctx.read<SessionCubit>().state;
    final user = session.user;
    if (user == null) return;
    convCubit.clearUnread(conversation.id);
    convCubit.clearMentionMe(conversation.id);
    convCubit.setActiveConversation(conversation.id);
    await Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => _buildChatRoute(ctx, conversation, user),
    ));
    convCubit.clearActiveConversation();
  }

  /// 构建 ChatPage 路由（含 BlocProvider 包裹）
  Widget _buildChatRoute(BuildContext ctx, Conversation conversation, User user) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: ctx.read<MessageRepository>()),
        RepositoryProvider.value(value: ctx.read<WsClient>()),
      ],
      child: BlocProvider(
        create: (_) => ChatCubit(
          repository: ctx.read<MessageRepository>(),
          wsClient: ctx.read<WsClient>(),
          context: ChatContext(
            conversationId: conversation.id,
            currentUserId: user.userId.toString(),
            currentUserName: user.nickname,
            currentUserAvatar: user.avatar,
            isGroup: conversation.isGroup,
          ),
          onConversationChanged: () => convCubit.loadConversations(),
        )..loadMessages(),
        child: ChatPage(
          conversationId: conversation.id,
          peerName: conversation.displayName,
          peerAvatar: conversation.displayAvatar,
          baseUrl: AppConfig.baseUrl,
          isGroup: conversation.isGroup,
          isDisband: false,
          announcement: null,
          peerUserId: conversation.peerUserId,
          groupDetailFetcher: conversation.isGroup
              ? () => ctx.read<GroupRepository>().getGroupDetail(conversation.id)
              : null,
          onAddMember: conversation.isGroup
              ? null
              : () => createGroupFromChat(ctx, conversation),
          onGroupInfo: conversation.isGroup
              ? () => _openGroupInfo(ctx, conversation, user)
              : null,
          onSearchChat: () => _openConversationSearch(ctx, conversation),
        ),
      ),
    );
  }

  /// 构建嵌入式 ChatPage（桌面端右侧面板使用，不含 Navigator.push）
  Widget buildChatPanel(BuildContext ctx, Conversation conversation) {
    final session = ctx.read<SessionCubit>().state;
    final user = session.user;
    if (user == null) return const SizedBox.shrink();
    return MultiRepositoryProvider(
      key: ValueKey(conversation.id),
      providers: [
        RepositoryProvider.value(value: ctx.read<MessageRepository>()),
        RepositoryProvider.value(value: ctx.read<WsClient>()),
      ],
      child: BlocProvider(
        create: (_) => ChatCubit(
          repository: ctx.read<MessageRepository>(),
          wsClient: ctx.read<WsClient>(),
          context: ChatContext(
            conversationId: conversation.id,
            currentUserId: user.userId.toString(),
            currentUserName: user.nickname,
            currentUserAvatar: user.avatar,
            isGroup: conversation.isGroup,
          ),
          onConversationChanged: () => convCubit.loadConversations(),
        )..loadMessages(),
        child: ChatPage(
          conversationId: conversation.id,
          peerName: conversation.displayName,
          peerAvatar: conversation.displayAvatar,
          baseUrl: AppConfig.baseUrl,
          isGroup: conversation.isGroup,
          peerUserId: conversation.peerUserId,
          embedded: true,
          groupDetailFetcher: conversation.isGroup
              ? () => ctx.read<GroupRepository>().getGroupDetail(conversation.id)
              : null,
        ),
      ),
    );
  }

  /// 通过 ID 打开聊天
  Future<void> openChatById(BuildContext ctx, String conversationId, {bool isGroup = false}) async {
    try {
      final conv = await ctx.read<ConversationRepository>().getById(conversationId);
      if (!ctx.mounted) return;
      openChat(ctx, conv);
    } catch (_) {}
  }

  /// 打开搜索
  void openSearch(BuildContext ctx) {
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => SearchPage(
        repository: ctx.read<SearchRepository>(),
        onFriendTap: (friendId) {
          final friends = ctx.read<FriendCubit>().state.friends;
          final friend = friends.where((f) => f.friendId == friendId).firstOrNull;
          if (friend != null) openFriendDetail(ctx, friend);
        },
        onGroupTap: (conversationId) => openChatById(ctx, conversationId, isGroup: true),
        onMessageTap: (conversationId, messageId) => openChatById(ctx, conversationId),
      ),
    ));
  }

  /// 打开好友详情
  void openFriendDetail(BuildContext ctx, Friend friend) {
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => FriendDetailPage(
        friend: friend,
        onSendMessage: () {
          Navigator.of(ctx).pop();
          startChatWithFriend(ctx, friend);
        },
        onDeleteFriend: () {
          ctx.read<FriendCubit>().deleteFriend(friend.friendId);
          Navigator.of(ctx).pop();
        },
      ),
    ));
  }

  /// 和好友开始聊天
  Future<void> startChatWithFriend(BuildContext ctx, Friend friend) async {
    final session = ctx.read<SessionCubit>().state;
    final user = session.user;
    if (user == null) return;
    try {
      final conv = await ctx.read<ConversationRepository>()
          .createPrivate(int.parse(friend.friendId));
      if (!ctx.mounted) return;
      openChat(ctx, conv);
    } catch (_) {}
  }

  /// 打开创建群聊
  Future<void> openCreateGroup(BuildContext ctx, {Set<String>? initialSelectedIds}) async {
    final members = friendsToMembers();
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => CreateGroupPage(
        members: members,
        initialSelectedIds: initialSelectedIds ?? const {},
        onCreated: (result) => _handleGroupCreated(ctx, result),
      ),
    ));
  }

  /// 从聊天页发起群聊
  Future<void> createGroupFromChat(BuildContext ctx, Conversation conversation) async {
    if (conversation.peerUserId == null) return;
    await openCreateGroup(ctx, initialSelectedIds: {conversation.peerUserId!});
  }

  /// 打开添加好友/群
  void openAddFriend(BuildContext ctx) {
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => AddFriendPage(
        repository: ctx.read<FriendRepository>(),
        onSearchGroup: () {
          Navigator.of(ctx).push(MaterialPageRoute(
            builder: (_) => SearchGroupPage(
              repository: ctx.read<GroupRepository>(),
              baseUrl: AppConfig.baseUrl,
            ),
          ));
        },
      ),
    ));
  }

  // ==================== 私有辅助方法 ====================

  Future<void> _handleGroupCreated(BuildContext ctx, CreateGroupResult result) async {
    try {
      final conv = await ctx.read<GroupRepository>()
          .createGroup(name: result.name, memberIds: result.memberIds);
      if (!ctx.mounted) return;
      convCubit.loadConversations();
      final session = ctx.read<SessionCubit>().state;
      final user = session.user;
      if (user == null) return;
      Navigator.of(ctx).pushReplacement(MaterialPageRoute(
        builder: (_) => _buildChatRoute(ctx, conv, user),
      ));
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('创建群聊失败：$e')),
      );
    }
  }

  void _openGroupInfo(BuildContext ctx, Conversation conversation, User user) {
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => GroupChatInfoPage(
        repository: ctx.read<GroupRepository>(),
        conversationId: conversation.id,
        baseUrl: AppConfig.baseUrl,
        currentUserId: user.userId.toString(),
        friendsFetcher: () async => friendsToMembers(),
        onLeaveOrDisband: () {
          Navigator.of(ctx).popUntil((route) => route.isFirst);
          convCubit.loadConversations();
        },
        onSearchChat: () => _openConversationSearch(ctx, conversation),
      ),
    ));
  }

  void _openConversationSearch(BuildContext ctx, Conversation conversation) {
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => ConversationSearchPage(
        conversationId: conversation.id,
        conversationName: conversation.displayName,
        repository: ctx.read<SearchRepository>(),
        onMessageTap: (convId, msgId) => Navigator.of(ctx).pop(),
      ),
    ));
  }
}
