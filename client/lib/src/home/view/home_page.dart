import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_im_core/flash_im_core.dart';
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

  @override
  void initState() {
    super.initState();
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
      const Center(
          child: Text('暂无联系人',
              style: TextStyle(fontSize: 16, color: Colors.grey))),
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
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    label: '通讯录',
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
      body: const Center(
        child: Text('暂无消息', style: TextStyle(fontSize: 16, color: Colors.grey)),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? _kPrimary : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 24),
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
}
