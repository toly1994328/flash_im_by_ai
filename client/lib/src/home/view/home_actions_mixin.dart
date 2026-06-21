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
import 'package:flash_auth/flash_auth.dart';
import '../../application/config.dart';

/// �������� mixin���ƶ��˺�����˹��õ�ҵ�����
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

  /// �����죨ȫ�� push���ƶ���ʹ�ã�
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

  /// 构建 ChatPage 组件，含 BlocProvider 包装层
  Widget _buildChatRoute(BuildContext ctx, Conversation conversation, User user) {
    final bool ossEnabled = ctx.read<SubscriptionCubit>().ossUploadEnabled;
    debugPrint('[DEBUG] _buildChatRoute: ossEnabled=$ossEnabled, state=${ctx.read<SubscriptionCubit>().state.hasActiveSubscription}');
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: ctx.read<MessageRepository>()),
        RepositoryProvider.value(value: ctx.read<WsClient>()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
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
              baseUrl: AppConfig.baseUrl,
              ossUploader: ossEnabled ? OssUploader(dio: ctx.read<MessageRepository>().dio) : null,
              ossUploadEnabled: ossEnabled,
            )..loadMessages(),
          ),
          if (conversation.isGroup)
            BlocProvider(
              create: (_) => ChatGroupCubit(
                conversationId: conversation.id,
                wsClient: ctx.read<WsClient>(),
                repository: ctx.read<MessageRepository>(),
                initialTitle: conversation.displayName,
                groupDetailFetcher: () => ctx.read<GroupRepository>().getGroupDetailRaw(conversation.id),
              ),
            ),
          if (!conversation.isGroup && conversation.peerUserId != null)
            BlocProvider(
              create: (_) => PeerStatusCubit(
                peerUserId: conversation.peerUserId!,
                wsClient: ctx.read<WsClient>(),
              ),
            ),
        ],
        child: ChatPage(
          target: ChatTarget(
            conversationId: conversation.id,
            isGroup: conversation.isGroup,
            peerName: conversation.displayName,
            peerAvatar: conversation.displayAvatar,
            peerUserId: conversation.peerUserId,
          ),
          viewOptions: ChatViewOptions(baseUrl: AppConfig.baseUrl),
          onAddMember: conversation.isGroup
              ? null
              : () => createGroupFromChat(ctx, conversation),
          onGroupInfo: conversation.isGroup
              ? () => _openGroupInfo(ctx, conversation, user)
              : null,
          onSearchChat: () => openConversationSearch(ctx, conversation),
        ),
      ),
    );
  }

  /// 构建嵌入式 ChatPage（桌面端也可以使用，不走 Navigator.push）
  Widget buildChatPanel(BuildContext ctx, Conversation conversation, {VoidCallback? onToggleDetail}) {
    final session = ctx.read<SessionCubit>().state;
    final user = session.user;
    if (user == null) return const SizedBox.shrink();
    final bool ossEnabled = ctx.read<SubscriptionCubit>().ossUploadEnabled;
    return MultiRepositoryProvider(
      key: ValueKey(conversation.id),
      providers: [
        RepositoryProvider.value(value: ctx.read<MessageRepository>()),
        RepositoryProvider.value(value: ctx.read<WsClient>()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
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
              baseUrl: AppConfig.baseUrl,
              ossUploader: ossEnabled ? OssUploader(dio: ctx.read<MessageRepository>().dio) : null,
              ossUploadEnabled: ossEnabled,
            )..loadMessages(),
          ),
          if (conversation.isGroup)
            BlocProvider(
              create: (_) => ChatGroupCubit(
                conversationId: conversation.id,
                wsClient: ctx.read<WsClient>(),
                repository: ctx.read<MessageRepository>(),
                initialTitle: conversation.displayName,
                groupDetailFetcher: () => ctx.read<GroupRepository>().getGroupDetailRaw(conversation.id),
              ),
            ),
          if (!conversation.isGroup && conversation.peerUserId != null)
            BlocProvider(
              create: (_) => PeerStatusCubit(
                peerUserId: conversation.peerUserId!,
                wsClient: ctx.read<WsClient>(),
              ),
            ),
        ],
        child: ChatPage(
          target: ChatTarget(
            conversationId: conversation.id,
            isGroup: conversation.isGroup,
            peerName: conversation.displayName,
            peerAvatar: conversation.displayAvatar,
            peerUserId: conversation.peerUserId,
          ),
          viewOptions: ChatViewOptions(baseUrl: AppConfig.baseUrl, embedded: true),
          onToggleDetail: onToggleDetail,
          onGroupInfo: conversation.isGroup ? () {
            final session = ctx.read<SessionCubit>().state;
            final user = session.user;
            if (user == null) return;
            Navigator.of(ctx).push(MaterialPageRoute(
              builder: (_) => GroupInfoScope(
                repository: ctx.read<GroupRepository>(),
                conversationId: conversation.id,
                currentUserId: user.userId.toString(),
                child: GroupChatInfoPage(
                  repository: ctx.read<GroupRepository>(),
                  conversationId: conversation.id,
                  baseUrl: AppConfig.baseUrl,
                  currentUserId: user.userId.toString(),
                  friendsFetcher: () async => friendsToMembers(),
                  onLeaveOrDisband: () {
                    Navigator.of(ctx).popUntil((route) => route.isFirst);
                    convCubit.loadConversations();
                  },
                  onSearchChat: () => openConversationSearch(ctx, conversation),
                ),
              ),
            ));
          } : null,
        ),
      ),
    );
  }

  /// ͨ�� ID ������
  Future<void> openChatById(BuildContext ctx, String conversationId, {bool isGroup = false}) async {
    try {
      final conv = await ctx.read<ConversationRepository>().getById(conversationId);
      if (!ctx.mounted) return;
      openChat(ctx, conv);
    } catch (_) {}
  }

  /// ������
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

  /// �򿪺�������
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

  /// �ͺ��ѿ�ʼ����
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

  /// �򿪴���Ⱥ��
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

  /// ������ҳ����Ⱥ��
  Future<void> createGroupFromChat(BuildContext ctx, Conversation conversation) async {
    if (conversation.peerUserId == null) return;
    await openCreateGroup(ctx, initialSelectedIds: {conversation.peerUserId!});
  }

  /// �����Ӻ���/Ⱥ
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
        onScanLogin: (scanToken) {
          final authRepo = ctx.read<AuthRepository>();
          Navigator.of(ctx).pushReplacement(MaterialPageRoute(
            builder: (_) => ScanConfirmPage(
              scanToken: scanToken,
              authRepository: authRepo,
            ),
          ));
        },
      ),
    ));
  }

  // ==================== ˽�и������� ====================

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
        SnackBar(content: Text('����Ⱥ��ʧ�ܣ�$e')),
      );
    }
  }

  void _openGroupInfo(BuildContext ctx, Conversation conversation, User user) {
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => GroupInfoScope(
        repository: ctx.read<GroupRepository>(),
        conversationId: conversation.id,
        currentUserId: user.userId.toString(),
        child: GroupChatInfoPage(
          repository: ctx.read<GroupRepository>(),
          conversationId: conversation.id,
          baseUrl: AppConfig.baseUrl,
          currentUserId: user.userId.toString(),
          friendsFetcher: () async => friendsToMembers(),
          onLeaveOrDisband: () {
            Navigator.of(ctx).popUntil((route) => route.isFirst);
            convCubit.loadConversations();
          },
          onSearchChat: () => openConversationSearch(ctx, conversation),
        ),
      ),
    ));
  }

  void openConversationSearch(BuildContext ctx, Conversation conversation) {
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
