import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fx_env/fx_env.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_shared/flash_shared.dart';
import 'package:flash_im_core/flash_im_core.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';
import 'package:flash_im_friend/flash_im_friend.dart';
import 'package:flash_im_group/flash_im_group.dart';
import 'package:flash_auth/flash_auth.dart';
import '../../application/config.dart';
import '../profile/profile_page.dart';
import 'home_page.dart';

const _kPrimary = Color(0xFF3B82F6);

class MobileLayout extends StatefulWidget {
  final HomePageState homeState;

  const MobileLayout({super.key, required this.homeState});

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  int _currentIndex = 0;

  HomePageState get _home => widget.homeState;

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
        centerTitle: kApp.isMacOS,
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
                  onTap: () => _home.openCreateGroup(context),
                ),
                WxMenuItem(
                  icon: Icons.person_add,
                  text: '加好友/群',
                  onTap: () => _home.openAddFriend(context),
                ),
                WxMenuItem(
                  icon: Icons.qr_code_scanner,
                  text: '扫一扫',
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ScanPage(
                        onUserScanned: (userId) async {
                          final repo = context.read<FriendRepository>();
                          final profile = await repo.getUserProfile(userId);
                          if (!context.mounted) return;
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => UserProfilePage(profile: profile, repository: repo),
                          ));
                        },
                        onScanLogin: (scanToken) {
                          final authRepo = context.read<AuthRepository>();
                          Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (_) => ScanConfirmPage(
                              scanToken: scanToken,
                              authRepository: authRepo,
                            ),
                          ));
                        },
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.2),
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
                                width: 8, height: 8,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.normal)),
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
            onTap: () => _home.openSearch(context),
          ),
          Expanded(
            child: BlocProvider.value(
              value: _home.convCubit,
              child: BlocBuilder<FriendCubit, FriendState>(
                builder: (context, friendState) {
                  return ConversationListPage(
                    onlineUserIds: friendState.onlineIds,
                    onConversationTap: (conv) => _home.openChat(context, conv),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsTab() {
    return BlocBuilder<GroupNotificationCubit, GroupNotificationState>(
      bloc: _home.groupNotifCubit,
      builder: (context, groupNotifState) {
        return FriendListPage(
          onFriendTap: (friend) => _home.openFriendDetail(context, friend),
          onSearchTap: () => _home.openSearch(context),
          onAddFriendTap: () => _home.openAddFriend(context),
          onRequestsTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<FriendCubit>(),
                child: FriendRequestPage(
                  onAddFriendTap: () => _home.openAddFriend(context),
                ),
              ),
            ));
          },
          onSearchGroupTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MyGroupsPage(
                repository: context.read<ConversationRepository>(),
                onGroupTap: (conversation) => _home.openChat(context, conversation),
              ),
            ));
          },
          onGroupNotificationsTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GroupNotificationsPage(
                repository: context.read<GroupRepository>(),
                baseUrl: AppConfig.baseUrl,
                notificationCubit: _home.groupNotifCubit,
              ),
            ));
            _home.groupNotifCubit.loadPendingCount();
          },
          groupNotificationCount: groupNotifState.pendingCount,
        );
      },
    );
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
      bloc: _home.convCubit,
      builder: (context, state) {
        final total = state is ConversationListLoaded ? state.totalUnread : 0;
        return UnreadBadge(count: total);
      },
    );
  }

  Widget? _buildPendingBadge() {
    return BlocBuilder<FriendCubit, FriendState>(
      builder: (context, friendState) {
        return BlocBuilder<GroupNotificationCubit, GroupNotificationState>(
          bloc: _home.groupNotifCubit,
          builder: (context, groupState) {
            final total = friendState.pendingCount + groupState.pendingCount;
            return UnreadBadge(count: total);
          },
        );
      },
    );
  }
}
