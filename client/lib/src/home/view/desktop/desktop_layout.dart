import 'package:flash_cloud/flash_cloud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fx_env/fx_env.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_shared/flash_shared.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';
import 'package:flash_im_friend/flash_im_friend.dart';
import 'package:flash_im_group/flash_im_group.dart';
import '../../../application/config.dart';
import '../../profile/desktop_settings_panel.dart';
import '../home_page.dart';
import 'nav_rail.dart';
import 'conversation_panel.dart';
import 'chat_detail_sidebar.dart';
import 'contact_detail_panel.dart';
import 'cloud_detail_panel.dart';
import 'actions_mixin.dart';

class DesktopLayout extends StatefulWidget {
  final HomePageState homeState;

  const DesktopLayout({super.key, required this.homeState});

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout>
    with SingleTickerProviderStateMixin, DesktopActionsMixin {
  int _navIndex = 0;
  Conversation? _selectedConv;
  Friend? _selectedFriend;
  bool _showChatDetail = false;
  String? _contactPanelType;
  CloudFile? _selectedCloudFile;

  late final AnimationController _detailAnimController;
  late final Animation<Offset> _detailSlideAnimation;

  HomePageState get _home => widget.homeState;

  @override
  void initState() {
    super.initState();
    _detailAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _detailSlideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _detailAnimController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _detailAnimController.dispose();
    super.dispose();
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          BlocBuilder<ConversationListCubit, ConversationListState>(
            bloc: _home.convCubit,
            builder: (context, convState) {
              final unread = convState is ConversationListLoaded ? convState.totalUnread : 0;
              return DesktopNavRail(
                navIndex: _navIndex,
                onNavChanged: (i) => setState(() => _navIndex = i),
                onMenuTap: () => showSettingsMenu(context),
                unreadCount: unread,
                onMenuSelect: (route) {
                  switch (route) {
                    case 'settings':
                      showSettingsDialogAction(context);
                    case 'feedback':
                      showFeedbackDialog(context, onSent: (convId) async {
                        try {
                          final conv = await context.read<ConversationRepository>().getById(convId);
                          if (!context.mounted) return;
                          _selectConversation(conv);
                        } catch (_) {}
                      });
                    case 'logout':
                      logoutAction(context);
                  }
                },
              );
            },
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_navIndex == 0) {
      return Row(
        children: [
          SizedBox(
            width: 320,
            child: DesktopConversationPanel(
              convCubit: _home.convCubit,
              activeConversationId: _selectedConv?.id,
              onSearchTap: _handleSearch,
              onCreateGroupTap: () => showCreateGroupDialog(
                context, _home.friendsToMembers(), _selectConversation,
              ),
              onAddFriendTap: () => showAddFriendDialog(context),
              onConversationTap: _selectConversation,
            ),
          ),
          const VerticalDivider(width: 0.5, thickness: 0.5),
          Expanded(child: _buildChatPanel()),
        ],
      );
    }
    if (_navIndex == 1) {
      return Row(
        children: [
          SizedBox(width: 360, child: _buildContactsPanel()),
          const VerticalDivider(width: 0.5, thickness: 0.5),
          Expanded(
            child: Column(
              children: [
                _buildContactDetailHeader(),
                Expanded(
                  child: DesktopContactDetailPanel(
                    panelType: _contactPanelType,
                    selectedFriend: _selectedFriend,
                    homeState: _home,
                    onAddFriendTap: () => showAddFriendDialog(context),
                    onConversationTap: _selectConversation,
                    onFriendDeleted: () {
                      context.read<FriendCubit>().deleteFriend(_selectedFriend!.friendId);
                      setState(() => _selectedFriend = null);
                    },
                    onSendMessage: () async {
                      final conv = await context.read<ConversationRepository>()
                          .createPrivate(int.parse(_selectedFriend!.friendId));
                      if (!context.mounted) return;
                      _selectConversation(conv);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (_navIndex == 2) {
      return Row(
        children: [
          SizedBox(
            width: 400,
            child: Column(
              children: [
                _buildCloudListHeader(),
                Expanded(child: _buildCloudListPanel()),
              ],
            ),
          ),
          const VerticalDivider(width: 0.5, thickness: 0.5),
          Expanded(
            child: Column(
              children: [
                _buildCloudDetailHeader(),
                Expanded(child: _buildCloudDetailPanel()),
              ],
            ),
          ),
        ],
      );
    }
    if (_navIndex == 3) {
      return BlocBuilder<SessionCubit, SessionState>(
        builder: (context, state) {
          return DesktopSettingsPanel(hasPassword: state.hasPassword);
        },
      );
    }
    return const SizedBox.shrink();
  }

  // ─── 云空间 Tab ───

  Widget _buildCloudListHeader() {
    return DragMoveArea(
      child: Container(
        height: kToolbarHeight,
        padding: const EdgeInsets.only(left: 16),
        color: context.imTheme.headerColor,
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Text('云空间', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
        ),
      ),
    );
  }

  Widget _buildCloudListPanel() {
    final CloudRepository cloudRepo = context.read<CloudRepository>();
    return CloudSpacePage(
      repository: cloudRepo,
      baseUrl: AppConfig.baseUrl,
      showAppBar: false,
      onFileTap: (CloudFile file) {
        setState(() => _selectedCloudFile = file);
      },
      onCategoryChanged: () {
        setState(() => _selectedCloudFile = null);
      },
    );
  }

  Widget _buildCloudDetailHeader() {
    final String title = _selectedCloudFile?.originalName
        ?? _selectedCloudFile?.url.split('/').last
        ?? '';
    return DragMoveArea(
      child: Container(
        height: kToolbarHeight,
        padding: const EdgeInsets.only(left: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE8E8E8), width: 0.5)),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (kApp.isWindows)
              const Positioned(top: 0, right: 0, child: WindowsButtons()),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudDetailPanel() {
    return DesktopCloudDetailPanel(
      selectedFile: _selectedCloudFile,
      repository: context.read<CloudRepository>(),
      baseUrl: AppConfig.baseUrl,
      onDeleted: () {
        setState(() => _selectedCloudFile = null);
      },
    );
  }

  // ─── 消息 Tab ───

  Widget _buildChatPanel() {
    if (_selectedConv == null) {
      return Stack(
        children: [
          DragMoveArea(
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
          ),
          if (kApp.isWindows)
            const Positioned(
              top: 0,
              right: 0,
              child: WindowsButtons(),
            ),
        ],
      );
    }
    return Stack(
      children: [
        _home.buildChatPanel(
          context,
          _selectedConv!,
          onToggleDetail: _toggleChatDetail,
        ),
        if (kApp.isWindows)
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildChatDetailButton(),
                const WindowsButtons(),
              ],
            ),
          ),
        if (kApp.isMacOS)
          Positioned(
            top: 6,
            right: 8,
            child: _buildChatDetailButton(),
          ),
        Positioned(
          top: kToolbarHeight + 0.5,
          bottom: 0,
          right: 0,
          width: 320,
          child: SlideTransition(
            position: _detailSlideAnimation,
            child: TapRegion(
              onTapOutside: _showChatDetail ? (_) => _toggleChatDetail() : null,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(left: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
                ),
                child: ChatDetailSidebar(
                  conversation: _selectedConv!,
                  homeState: _home,
                  onLeaveOrDisband: () {
                    setState(() {
                      _selectedConv = null;
                      _showChatDetail = false;
                    });
                    _detailAnimController.reverse();
                    _home.convCubit.loadConversations();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── 通讯录 Tab ───

  Widget _buildContactsPanel() {
    return Column(
      children: [
        DragMoveArea(child: Container(height: 24, color: context.imTheme.headerColor)),
        Expanded(
          child: BlocBuilder<GroupNotificationCubit, GroupNotificationState>(
            bloc: _home.groupNotifCubit,
            builder: (context, groupNotifState) {
              return FriendListPage(
                showAppBar: false,
                onFriendTap: (friend) => setState(() {
                  _selectedFriend = friend;
                  _contactPanelType = null;
                }),
                onSearchTap: _handleSearch,
                onAddFriendTap: () => showAddFriendDialog(context),
                onRequestsTap: () => setState(() {
                  _selectedFriend = null;
                  _contactPanelType = 'requests';
                }),
                onSearchGroupTap: () => setState(() {
                  _selectedFriend = null;
                  _contactPanelType = 'groups';
                }),
                onGroupNotificationsTap: () => setState(() {
                  _selectedFriend = null;
                  _contactPanelType = 'notifications';
                }),
                groupNotificationCount: groupNotifState.pendingCount,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactDetailHeader() {
    final title = switch (_contactPanelType) {
      'requests' => '新的朋友',
      'groups' => '群聊',
      'notifications' => '群通知',
      _ => _selectedFriend?.nickname ?? '',
    };
    return DragMoveArea(
      child: Container(
        height: kToolbarHeight,
        padding: const EdgeInsets.only(left: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE8E8E8), width: 0.5)),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
              ),
            ),
            const Positioned(top: 0, right: 0, child: WindowsButtons()),
          ],
        ),
      ),
    );
  }

  // ─── 事件处理 ───

  Widget _buildChatDetailButton() {
    final bool isGroup = _selectedConv?.isGroup ?? false;
    return GestureDetector(
      onTap: _toggleChatDetail,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(
          isGroup ? Icons.group : Icons.more_horiz,
          size: 20,
          color: const Color(0xFF555555),
        ),
      ),
    );
  }

  void _toggleChatDetail() {
    setState(() => _showChatDetail = !_showChatDetail);
    if (_showChatDetail) {
      _detailAnimController.forward();
    } else {
      _detailAnimController.reverse();
    }
  }

  void _selectConversation(Conversation conv) {
    setState(() {
      _navIndex = 0;
      _selectedConv = conv;
      _showChatDetail = false;
    });
    _home.convCubit.clearUnread(conv.id);
    _home.convCubit.clearMentionMe(conv.id);
    _home.convCubit.setActiveConversation(conv.id);
    if (_showChatDetail) _detailAnimController.reverse();

  }

  void _handleSearch() {
    showSearchDialog(
      context,
      onFriendTap: (friendId) {
        final friends = context.read<FriendCubit>().state.friends;
        final friend = friends.where((f) => f.friendId == friendId).firstOrNull;
        if (friend != null) {
          setState(() {
            _navIndex = 1;
            _selectedFriend = friend;
            _contactPanelType = null;
          });
        }
      },
      onGroupTap: (conversationId) async {
        try {
          final conv = await context.read<ConversationRepository>().getById(conversationId);
          if (!context.mounted) return;
          _selectConversation(conv);
        } catch (_) {}
      },
      onMessageTap: (conversationId, _) async {
        try {
          final conv = await context.read<ConversationRepository>().getById(conversationId);
          if (!context.mounted) return;
          _selectConversation(conv);
        } catch (_) {}
      },
    );
  }
}
