import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_shared/flash_shared.dart';
import 'package:tolyui_navigation/tolyui_navigation.dart';

/// 桌面端侧边导航栏
class DesktopNavRail extends StatelessWidget {
  final int navIndex;
  final ValueChanged<int> onNavChanged;
  final VoidCallback onMenuTap;
  final ValueChanged<String>? onMenuSelect;
  final int unreadCount;

  const DesktopNavRail({
    super.key,
    required this.navIndex,
    required this.onNavChanged,
    required this.onMenuTap,
    this.onMenuSelect,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DragMoveArea(
      child: Container(
        width: 68,
        color: context.imTheme.sidebarColor,
        child: Column(
          children: [
            const SizedBox(height: 38),
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
            _buildNavIcon(context, 0, Icons.chat_bubble_outline, Icons.chat_bubble, '消息', badge: unreadCount),
            const SizedBox(height: 12),
            _buildNavIcon(context, 1, Icons.people_outline, Icons.people, '通讯录'),
            const SizedBox(height: 12),
            _buildNavIcon(context, 2, Icons.cloud_outlined, Icons.cloud, '云空间'),
            const SizedBox(height: 12),
            _buildNavIcon(context, 3, Icons.person_outline, Icons.person, '我的'),
            const Spacer(),
            TolyDropMenu(
              placement: Placement.rightEnd,
              decorationConfig: const DecorationConfig(
                isBubble: false,
                backgroundColor: Colors.white,
                radius: Radius.circular(8),
                shadows: [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, -2))],
              ),
              menuItems: [
                ActionMenu(const MenuMeta(route: 'settings', label: '系统设置')),
                ActionMenu(const MenuMeta(route: 'feedback', label: '意见反馈')),
                ActionMenu(const MenuMeta(route: 'logout', label: '退出登录')),
              ],
              onSelect: (menu) => onMenuSelect?.call(menu.route),
              childBuilder: (context, ctrl, child) => GestureDetector(
                onTap: () => ctrl.open(),
                child: child,
              ),
              child: const Icon(Icons.menu, size: 22, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(BuildContext context, int index, IconData icon, IconData activeIcon, String label, {int badge = 0}) {
    final isSelected = navIndex == index;
    return GestureDetector(
      onTap: () => onNavChanged(index),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? context.imTheme.navActiveColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
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
            if (badge > 0)
              Positioned(
                top: -4,
                right: -2,
                child: UnreadBadge(count: badge, size: BadgeSize.medium),
              ),
          ],
        ),
      ),
    );
  }
}
