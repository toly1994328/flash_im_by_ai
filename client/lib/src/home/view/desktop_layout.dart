import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_shared/flash_shared.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';
import 'package:flash_im_friend/flash_im_friend.dart';
import 'package:flash_im_group/flash_im_group.dart';
import '../../application/config.dart';
import '../profile/profile_page.dart';
import '../profile/settings_page.dart';
import 'home_page.dart';

const _kPrimary = Color(0xFF3B82F6);

class DesktopLayout extends StatefulWidget {
  final HomePageState homeState;

  const DesktopLayout({super.key, required this.homeState});

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  int _navIndex = 0;
  Conversation? _selectedConv;
  Friend? _selectedFriend;

  HomePageState get _home => widget.homeState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildNavigationRail(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_navIndex == 0) {
      // 消息 Tab：三栏（会话列表 + 聊天区）
      return Row(
        children: [
          SizedBox(width: 320, child: _buildConversationPanel()),
          const VerticalDivider(width: 0.5, thickness: 0.5),
          Expanded(child: _buildDetailPanel()),
        ],
      );
    }
    if (_navIndex == 1) {
      // 通讯录 Tab：三栏（好友列表 + 好友详情）
      return Row(
        children: [
          SizedBox(width: 320, child: _buildContactsPanel()),
          const VerticalDivider(width: 0.5, thickness: 0.5),
          Expanded(child: _buildContactDetailPanel()),
        ],
      );
    }
    if (_navIndex == 2) return const ProfilePage();
    // 设置按钮：直接展示设置页
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        return SettingsPage(hasPassword: state.hasPassword);
      },
    );
  }

  Widget _buildNavigationRail() {
    return DragMoveArea(
      child: Container(
        width: 68,
        color: context.imTheme.sidebarColor,
        child: Column(
          children: [
            // 顶部留出红绿灯空间
            const SizedBox(height: 38),
            // 用户头像
            BlocBuilder<SessionCubit, SessionState>(
              builder: (context, state) {
                final user = state.user;
                if (user == null) return const SizedBox(height: 40);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: UserAvatar(user: user, size: 36, borderRadius: 8),
                );
              },
            ),
            // 导航图标
            _buildNavIcon(0, Icons.chat_bubble_outline, Icons.chat_bubble, '消息'),
            const SizedBox(height: 12),
            _buildNavIcon(1, Icons.people_outline, Icons.people, '通讯录'),
            const SizedBox(height: 12),
            _buildNavIcon(2, Icons.person_outline, Icons.person, '我的'),
            const Spacer(),
            // 底部设置按钮（无文字）
            GestureDetector(
              onTap: () => setState(() => _navIndex = 3),
              child: Icon(
                Icons.settings_outlined,
                size: 22,
                color: _navIndex == 3 ? context.imTheme.primary : const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _navIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _navIndex = index),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? context.imTheme.navActiveColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 20,
              color: isSelected ? context.imTheme.primary : const Color(0xFF666666),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? context.imTheme.primary : const Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildConversationPanel() {
    return Column(
      children: [
        // 顶部搜索栏 + 操作按钮
        Container(
          padding: const EdgeInsets.only(left: 12, right: 8, top: 14, bottom: 14),
          color: context.imTheme.headerColor,
          child: Row(
            children: [
              Expanded(
                child: DragMoveArea(
                  child: GestureDetector(
                    onTap: () => _home.openSearch(context),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 16, color: Color(0xFFBBBBBB)),
                          SizedBox(width: 4),
                          Text('搜索', style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              WxPopupMenuButton(
                items: [
                  WxMenuItem(icon: Icons.group_add, text: '发起群聊', onTap: () => _home.openCreateGroup(context)),
                  WxMenuItem(icon: Icons.person_add, text: '加好友/群', onTap: () => _home.openAddFriend(context)),
                ],
                child: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocProvider.value(
            value: _home.convCubit,
            child: BlocBuilder<FriendCubit, FriendState>(
              builder: (context, friendState) {
                return ConversationListPage(
                  onlineUserIds: friendState.onlineIds,
                  activeConversationId: _selectedConv?.id,
                  onConversationTap: (conv) => _selectConversation(conv),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactsPanel() {
    return BlocBuilder<GroupNotificationCubit, GroupNotificationState>(
      bloc: _home.groupNotifCubit,
      builder: (context, groupNotifState) {
        return FriendListPage(
          onFriendTap: (friend) => setState(() => _selectedFriend = friend),
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
                onGroupTap: (conversation) {
                  Navigator.of(context).pop();
                  _selectConversation(conversation);
                },
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

  Widget _buildDetailPanel() {
    if (_selectedConv == null) {
      return DragMoveArea(
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Color(0xFFDDDDDD)),
              SizedBox(height: 16),
              Text('选择一个会话开始聊天', style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
            ],
          ),
        ),
      );
    }
    return _home.buildChatPanel(context, _selectedConv!);
  }

  Widget _buildContactDetailPanel() {
    if (_selectedFriend == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 64, color: Color(0xFFDDDDDD)),
            SizedBox(height: 16),
            Text('选择一个好友查看详情', style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
          ],
        ),
      );
    }
    return FriendDetailPage(
      key: ValueKey(_selectedFriend!.friendId),
      friend: _selectedFriend!,
      onSendMessage: () async {
        final conv = await context.read<ConversationRepository>()
            .createPrivate(int.parse(_selectedFriend!.friendId));
        if (!context.mounted) return;
        setState(() {
          _navIndex = 0;
          _selectedConv = conv;
        });
        _home.convCubit.setActiveConversation(conv.id);
      },
      onDeleteFriend: () {
        context.read<FriendCubit>().deleteFriend(_selectedFriend!.friendId);
        setState(() => _selectedFriend = null);
      },
    );
  }

  void _selectConversation(Conversation conv) {
    _home.convCubit.clearUnread(conv.id);
    _home.convCubit.clearMentionMe(conv.id);
    _home.convCubit.setActiveConversation(conv.id);
    setState(() => _selectedConv = conv);
  }
}
