import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_im_core/flash_im_core.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';
import 'package:flash_im_chat/flash_im_chat.dart';
import 'package:flash_im_friend/flash_im_friend.dart';
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

  @override
  void initState() {
    super.initState();
    _convCubit = ConversationListCubit(
      context.read<ConversationRepository>(),
      wsClient: context.read<WsClient>(),
    )..loadConversations();
    context.read<FriendCubit>().loadFriends();
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
      body: BlocProvider.value(
        value: _convCubit,
        child: ConversationListPage(
          onConversationTap: (conversation) {
            final session = context.read<SessionCubit>().state;
            final user = session.user;
            if (user == null) return;
            _convCubit.clearUnread(conversation.id);
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
                  )..loadMessages(),
                  child: ChatPage(
                    conversationId: conversation.id,
                    peerName: conversation.displayName,
                    peerAvatar: conversation.displayAvatar,
                    baseUrl: AppConfig.baseUrl,
                  ),
                ),
              ),
            ));
          },
        ),
      ),
    );
  }

  Widget _buildContactsTab() {
    return FriendListPage(
      onFriendTap: (friend) => _openFriendDetail(context, friend),
      onAddFriendTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AddFriendPage(
            repository: context.read<FriendRepository>(),
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
                  ),
                ));
              },
            ),
          ),
        ));
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
            ),
          ),
        ),
      ));
    } catch (_) {}
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
      builder: (context, state) {
        if (state.pendingCount <= 0) return const SizedBox.shrink();
        final text = state.pendingCount > 99 ? '99+' : '${state.pendingCount}';
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
}
