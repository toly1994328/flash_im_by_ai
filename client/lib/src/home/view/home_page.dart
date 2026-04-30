import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_shared/flash_shared.dart';
import 'package:flash_im_core/flash_im_core.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';
import 'package:flash_im_chat/flash_im_chat.dart';
import 'package:flash_im_friend/flash_im_friend.dart';
import 'package:flash_im_group/flash_im_group.dart';
import 'package:flash_im_search/flash_im_search.dart';
import '../../../main.dart' show globalSyncEngine;
import '../../application/config.dart';
import '../profile/profile_page.dart';

const _kPrimary = Color(0xFF3B82F6);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _hasShownPasswordGuide = false;
  late final ConversationListCubit _convCubit;
  late final GroupNotificationCubit _groupNotifCubit;

  @override
  void initState() {
    super.initState();
    _convCubit = ConversationListCubit(
      context.read<ConversationRepository>(),
      wsClient: context.read<WsClient>(),
    )..loadConversations();
    context.read<FriendCubit>().loadFriends();

    // 注册 SyncEngine 回调：同步完成后自动刷新
    final se = globalSyncEngine;
    if (se != null) {
      se.onConversationChanged = () => _convCubit.loadConversations();
      se.onFriendListChanged = () => context.read<FriendCubit>().loadFriends();
    }
    _groupNotifCubit = GroupNotificationCubit(
      repository: context.read<GroupRepository>(),
      groupJoinRequestStream: context.read<WsClient>().groupJoinRequestStream,
    )..loadPendingCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPasswordGuide();
    });
  }

  void _checkPasswordGuide() {
    final state = context.read<SessionCubit>().state;
    if (state.status == SessionStatus.active &&
        !state.hasPassword &&
        !_hasShownPasswordGuide) {
      _hasShownPasswordGuide = true;
      _showPasswordGuideDialog();
    }
  }

  void _showPasswordGuideDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.white,
        title: const Text('设置密码'),
        content: const Text('建议设置密码，方便下次快速登录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('跳过'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<SessionCubit>(),
                    child: const SetPasswordPage(),
                  ),
                ),
              );
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pages = [
      _buildMessageTab(),
      _buildContactsTab(),
      const ProfilePage(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(index: _currentIndex, children: pages),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.chat_bubble_outline,
                    activeIcon: Icons.chat_bubble,
                    label: '消息',
                    badge: _buildUnreadBadge(),
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    label: '通讯录',
                    badge: _buildPendingBadge(),
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: '我',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageTab() {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        titleSpacing: 12,
        centerTitle: false,
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: WxPopupMenuButton(
              items: [
                WxMenuItem(
                  icon: Icons.group_add,
                  text: '发起群聊',
                  onTap: () => _openCreateGroup(context),
                ),
                WxMenuItem(
                  icon: Icons.person_add,
                  text: '加好友/群',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AddFriendPage(
                        repository: context.read<FriendRepository>(),
                        onSearchGroup: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SearchGroupPage(
                              repository: context.read<GroupRepository>(),
                              baseUrl: AppConfig.baseUrl,
                            ),
                          ));
                        },
                      ),
                    ));
                  },
                ),
                WxMenuItem(
                  icon: Icons.qr_code_scanner,
                  text: '扫一扫',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ScanPage(
                        repository: context.read<FriendRepository>(),
                      ),
                    ));
                  },
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.add_circle_outline, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        title: BlocBuilder<SessionCubit, SessionState>(
          builder: (context, state) {
            final user = state.user;
            final wsClient = context.read<WsClient>();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user != null) ...[
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: UserAvatar(user: user, size: 32, borderRadius: 16, paddingRatio: 0.22),
                  ),
                  const SizedBox(width: 8),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.nickname ?? '闪讯',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    StreamBuilder<WsConnectionState>(
                      stream: wsClient.stateStream,
                      initialData: wsClient.state,
                      builder: (context, snapshot) {
                        final wsState = snapshot.data ?? WsConnectionState.disconnected;
                        final (text, color) = switch (wsState) {
                          WsConnectionState.disconnected => ('连接已断开，点击重试', Colors.red),
                          WsConnectionState.connecting => ('连接中...', Colors.orange),
                          WsConnectionState.authenticating => ('认证中...', Colors.orange),
                          WsConnectionState.authenticated => ('已连接', const Color(0xFF4CAF50)),
                        };
                        return GestureDetector(
                          onTap: wsState == WsConnectionState.disconnected
                              ? () => wsClient.connect()
                              : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                text,
                                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          FlashSearchBar(
            hintText: '搜索',
            onTap: () => _openSearch(context),
          ),
          Expanded(
            child: BlocProvider.value(
              value: _convCubit,
              child: BlocBuilder<FriendCubit, FriendState>(
                builder: (context, friendState) {
                  return ConversationListPage(
                    onlineUserIds: friendState.onlineIds,
                    onConversationTap: (conv) => _openChat(context, conv),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SearchPage(
        repository: context.read<SearchRepository>(),
        onFriendTap: (friendId) {
          final friends = context.read<FriendCubit>().state.friends;
          final friend = friends.where((f) => f.friendId == friendId).firstOrNull;
          if (friend != null) {
            _openFriendDetail(context, friend);
          }
        },
        onGroupTap: (conversationId) {
          _openChatById(context, conversationId, isGroup: true);
        },
        onMessageTap: (conversationId, messageId) {
          _openChatById(context, conversationId);
        },
      ),
    ));
  }

  Future<void> _openChatById(BuildContext context, String conversationId, {bool isGroup = false}) async {
    final session = context.read<SessionCubit>().state;
    final user = session.user;
    if (user == null) return;
    try {
      final conv = await context.read<ConversationRepository>().getById(conversationId);
      if (!mounted) return;
      _openChat(context, conv);
    } catch (_) {}
  }

  Future<void> _openChat(BuildContext context, Conversation conversation) async {
    final session = context.read<SessionCubit>().state;
    final user = session.user;
    if (user == null) return;
    _convCubit.clearUnread(conversation.id);
    _convCubit.setActiveConversation(conversation.id);
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: context.read<MessageRepository>()),
          RepositoryProvider.value(value: context.read<WsClient>()),
        ],
        child: BlocProvider(
          create: (_) => ChatCubit(
            repository: context.read<MessageRepository>(),
            wsClient: context.read<WsClient>(),
            conversationId: conversation.id,
            currentUserId: user.userId.toString(),
            currentUserName: user.nickname,
            currentUserAvatar: user.avatar,
            isGroup: conversation.isGroup,
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
            groupDetailFetcher: conversation.isGroup ? () =>
                context.read<GroupRepository>().getGroupDetail(conversation.id) : null,
            onAddMember: conversation.isGroup ? null : () {
              _createGroupFromChat(context, conversation);
            },
            onGroupInfo: conversation.isGroup ? () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => GroupChatInfoPage(
                  repository: context.read<GroupRepository>(),
                  conversationId: conversation.id,
                  baseUrl: AppConfig.baseUrl,
                  currentUserId: user.userId.toString(),
                  friendsFetcher: () async => _friendsToMembers(),
                  onLeaveOrDisband: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    _convCubit.loadConversations();
                  },
                  onSearchChat: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ConversationSearchPage(
                        conversationId: conversation.id,
                        conversationName: conversation.displayName,
                        repository: context.read<SearchRepository>(),
                      ),
                    ));
                  },
                ),
              ));
            } : null,
            onSearchChat: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ConversationSearchPage(
                  conversationId: conversation.id,
                  conversationName: conversation.displayName,
                  repository: context.read<SearchRepository>(),
                  onMessageTap: (convId, msgId) {
                    Navigator.of(context).pop(); // 关闭搜索页
                  },
                ),
              ));
            },
          ),
        ),
      ),
    ));
    _convCubit.clearActiveConversation();
  }

  Widget _buildContactsTab() {
    return BlocBuilder<GroupNotificationCubit, GroupNotificationState>(
      bloc: _groupNotifCubit,
      builder: (context, groupNotifState) {
        return FriendListPage(
          onFriendTap: (friend) => _openFriendDetail(context, friend),
          onSearchTap: () => _openSearch(context),
          onAddFriendTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AddFriendPage(
                repository: context.read<FriendRepository>(),
                onSearchGroup: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SearchGroupPage(
                      repository: context.read<GroupRepository>(),
                      baseUrl: AppConfig.baseUrl,
                    ),
                  ));
                },
              ),
            ));
          },
          onRequestsTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<FriendCubit>(),
                child: FriendRequestPage(
                  onAddFriendTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AddFriendPage(
                        repository: context.read<FriendRepository>(),
                        onSearchGroup: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SearchGroupPage(
                              repository: context.read<GroupRepository>(),
                              baseUrl: AppConfig.baseUrl,
                            ),
                          ));
                        },
                      ),
                    ));
                  },
                ),
              ),
            ));
          },
          onSearchGroupTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MyGroupsPage(
                repository: context.read<ConversationRepository>(),
                onGroupTap: (conversation) {
                  final session = context.read<SessionCubit>().state;
                  final user = session.user;
                  if (user == null) return;
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MultiRepositoryProvider(
                      providers: [
                        RepositoryProvider.value(value: context.read<MessageRepository>()),
                        RepositoryProvider.value(value: context.read<WsClient>()),
                      ],
                      child: BlocProvider(
                        create: (_) => ChatCubit(
                          repository: context.read<MessageRepository>(),
                          wsClient: context.read<WsClient>(),
                          conversationId: conversation.id,
                          currentUserId: user.userId.toString(),
                          currentUserName: user.nickname,
                          currentUserAvatar: user.avatar,
                          isGroup: true,
                        )..loadMessages(),
                        child: ChatPage(
                          conversationId: conversation.id,
                          peerName: conversation.displayName,
                          peerAvatar: conversation.displayAvatar,
                          baseUrl: AppConfig.baseUrl,
                          isGroup: true,
                          isDisband: false,
                          announcement: null,
                          groupDetailFetcher: () =>
                              context.read<GroupRepository>().getGroupDetail(conversation.id),
                          onGroupInfo: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => GroupChatInfoPage(
                                repository: context.read<GroupRepository>(),
                                conversationId: conversation.id,
                                baseUrl: AppConfig.baseUrl,
                                currentUserId: user.userId.toString(),
                                friendsFetcher: () async => _friendsToMembers(),
                                onLeaveOrDisband: () {
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                  _convCubit.loadConversations();
                                },
                                onSearchChat: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => ConversationSearchPage(
                                      conversationId: conversation.id,
                                      conversationName: conversation.displayName,
                                      repository: context.read<SearchRepository>(),
                                    ),
                                  ));
                                },
                              ),
                            ));
                          },
                        ),
                      ),
                    ),
                  ));
                },
              ),
            ));
          },
          onGroupNotificationsTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GroupNotificationsPage(
                repository: context.read<GroupRepository>(),
                baseUrl: AppConfig.baseUrl,
                notificationCubit: _groupNotifCubit,
              ),
            ));
            _groupNotifCubit.loadPendingCount();
          },
          groupNotificationCount: groupNotifState.pendingCount,
        );
      },
    );
  }

  void _openFriendDetail(BuildContext context, Friend friend) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FriendDetailPage(
        friend: friend,
        onSendMessage: () {
          Navigator.of(context).pop(); // 关闭详情页
          _startChatWithFriend(context, friend);
        },
        onDeleteFriend: () {
          context.read<FriendCubit>().deleteFriend(friend.friendId);
          Navigator.of(context).pop(); // 关闭详情页
        },
      ),
    ));
  }

  Future<void> _startChatWithFriend(BuildContext context, Friend friend) async {
    final session = context.read<SessionCubit>().state;
    final user = session.user;
    if (user == null) return;
    try {
      final conv = await context.read<ConversationRepository>()
          .createPrivate(int.parse(friend.friendId));
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: context.read<MessageRepository>()),
            RepositoryProvider.value(value: context.read<WsClient>()),
          ],
          child: BlocProvider(
            create: (_) => ChatCubit(
              repository: context.read<MessageRepository>(),
              wsClient: context.read<WsClient>(),
              conversationId: conv.id,
              currentUserId: user.userId.toString(),
              currentUserName: user.nickname,
              currentUserAvatar: user.avatar,
            )..loadMessages(),
            child: ChatPage(
              conversationId: conv.id,
              peerName: friend.nickname,
              peerAvatar: friend.avatar,
              baseUrl: AppConfig.baseUrl,
              isGroup: false,
              peerUserId: friend.friendId,
              onAddMember: () {
                _createGroupFromChat(context, Conversation(
                  id: conv.id,
                  type: 0,
                  peerUserId: friend.friendId,
                  peerNickname: friend.nickname,
                  peerAvatar: friend.avatar,
                  createdAt: DateTime.now(),
                ));
              },
            ),
          ),
        ),
      ));
    } catch (_) {}
  }

  // ==================== 群聊相关方法 ====================

  List<SelectableMember> _friendsToMembers() {
    return context.read<FriendCubit>().state.friends
        .map((f) => SelectableMember(
          id: f.friendId,
          nickname: f.nickname,
          avatar: f.avatar,
          letter: PinyinUtil.getFirstLetter(f.nickname),
        ))
        .toList();
  }

  Future<void> _openCreateGroup(BuildContext context, {Set<String>? initialSelectedIds}) async {
    final members = _friendsToMembers();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateGroupPage(
          members: members,
          initialSelectedIds: initialSelectedIds ?? const {},
          onCreated: (result) => _handleGroupCreated(context, result),
        ),
      ),
    );
  }

  Future<void> _handleGroupCreated(BuildContext context, CreateGroupResult result) async {
    try {
      final conv = await context.read<GroupRepository>()
          .createGroup(name: result.name, memberIds: result.memberIds);
      if (!mounted) return;
      _convCubit.loadConversations();
      final session = context.read<SessionCubit>().state;
      final user = session.user;
      if (user == null) return;
      // push ChatPage 替换 CreateGroupPage，用户看到直接进入聊天
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: context.read<MessageRepository>()),
            RepositoryProvider.value(value: context.read<WsClient>()),
          ],
          child: BlocProvider(
            create: (_) => ChatCubit(
              repository: context.read<MessageRepository>(),
              wsClient: context.read<WsClient>(),
              conversationId: conv.id,
              currentUserId: user.userId.toString(),
              currentUserName: user.nickname,
              currentUserAvatar: user.avatar,
              isGroup: true,
            )..loadMessages(),
            child: ChatPage(
              conversationId: conv.id,
              peerName: conv.displayName,
              peerAvatar: conv.displayAvatar,
              baseUrl: AppConfig.baseUrl,
              isGroup: true,
              isDisband: false,
              announcement: null,
              groupDetailFetcher: () =>
                  context.read<GroupRepository>().getGroupDetail(conv.id),
              onGroupInfo: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => GroupChatInfoPage(
                    repository: context.read<GroupRepository>(),
                    conversationId: conv.id,
                    baseUrl: AppConfig.baseUrl,
                    currentUserId: user.userId.toString(),
                    friendsFetcher: () async => _friendsToMembers(),
                    onLeaveOrDisband: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      _convCubit.loadConversations();
                    },
                    onSearchChat: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ConversationSearchPage(
                          conversationId: conv.id,
                          conversationName: conv.displayName,
                          repository: context.read<SearchRepository>(),
                        ),
                      ));
                    },
                  ),
                ));
              },
            ),
          ),
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建群聊失败：$e')),
        );
      }
    }
  }

  Future<void> _createGroupFromChat(BuildContext context, Conversation conversation) async {
    if (conversation.peerUserId == null) return;
    await _openCreateGroup(context, initialSelectedIds: {conversation.peerUserId!});
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    Widget? badge,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? _kPrimary : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isSelected ? activeIcon : icon, color: color, size: 24),
                if (badge != null) Positioned(right: -8, top: -4, child: badge),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildUnreadBadge() {
    return BlocBuilder<ConversationListCubit, ConversationListState>(
      bloc: _convCubit,
      builder: (context, state) {
        final total = state is ConversationListLoaded ? state.totalUnread : 0;
        if (total <= 0) return const SizedBox.shrink();
        final text = total > 99 ? '99+' : total.toString();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
        );
      },
    );
  }

  Widget? _buildPendingBadge() {
    return BlocBuilder<FriendCubit, FriendState>(
      builder: (context, friendState) {
        return BlocBuilder<GroupNotificationCubit, GroupNotificationState>(
          bloc: _groupNotifCubit,
          builder: (context, groupState) {
            final total = friendState.pendingCount + groupState.pendingCount;
            if (total <= 0) return const SizedBox.shrink();
            final text = total > 99 ? '99+' : '$total';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
            );
          },
        );
      },
    );
  }
}
