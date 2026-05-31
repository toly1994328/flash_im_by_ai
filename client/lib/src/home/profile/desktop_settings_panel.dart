import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_shared/flash_shared.dart';
import 'package:flash_im_core/flash_im_core.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/config.dart';
import 'about_page.dart';

/// 桌面端设置三栏面板（参考微信桌面端设置页）
///
/// 左侧：设置菜单列表（固定宽度 220）
/// 右侧：对应设置内容区（Expanded）
class DesktopSettingsPanel extends StatefulWidget {
  final bool hasPassword;

  const DesktopSettingsPanel({super.key, required this.hasPassword});

  @override
  State<DesktopSettingsPanel> createState() => _DesktopSettingsPanelState();
}

class _DesktopSettingsPanelState extends State<DesktopSettingsPanel> {
  int _selectedIndex = 0;

  static const _menuItems = [
    _MenuItem(icon: Icons.person_outline, label: '个人资料'),
    _MenuItem(icon: Icons.lock_outline, label: '修改密码'),
    _MenuItem(icon: Icons.info_outline, label: '关于闪讯'),
    _MenuItem(icon: Icons.description_outlined, label: '用户协议'),
    _MenuItem(icon: Icons.shield_outlined, label: '隐私政策'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧菜单
        Container(
          width: 220,
          color: context.imTheme.scaffoldColor,
          child: Column(
            children: [
              const DragMoveArea(child: SizedBox(height: 38)),
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 8, bottom: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                ),
              ),
              Expanded(child: _buildMenuList()),
              _buildLogoutButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const VerticalDivider(width: 0.5, thickness: 0.5),
        // 右侧内容区
        Expanded(
          child: Column(
            children: [
              _buildContentHeader(),
              Expanded(child: _buildContentArea()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        final isSelected = _selectedIndex == index;
        // 密码项动态文案
        final label = index == 1
            ? (widget.hasPassword ? '修改密码' : '设置密码')
            : item.label;

        return GestureDetector(
          onTap: () => _onMenuTap(index),
          child: Container(
            height: 44,
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.imTheme.activeConversationColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected
                      ? context.imTheme.primary
                      : const Color(0xFF666666),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected
                        ? context.imTheme.primary
                        : const Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onMenuTap(int index) {
    // 用户协议和隐私政策直接打开浏览器
    if (index == 3) {
      launchUrl(Uri.parse('${AppConfig.baseUrl}/static/agreement.html'));
      return;
    }
    if (index == 4) {
      launchUrl(Uri.parse('${AppConfig.baseUrl}/static/privacy.html'));
      return;
    }
    setState(() => _selectedIndex = index);
  }

  Widget _buildContentHeader() {
    final title = switch (_selectedIndex) {
      0 => '个人资料',
      1 => widget.hasPassword ? '修改密码' : '设置密码',
      2 => '关于闪讯',
      _ => '',
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

  Widget _buildContentArea() {
    final page = switch (_selectedIndex) {
      0 => const EditProfilePage(),
      1 => widget.hasPassword ? const ChangePasswordPage() : const SetPasswordPage(),
      2 => const AboutPage(),
      3 => const _ExternalLinkPlaceholder(title: '用户协议', hint: '已在浏览器中打开'),
      4 => const _ExternalLinkPlaceholder(title: '隐私政策', hint: '已在浏览器中打开'),
      _ => const SizedBox.shrink(),
    };
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: const AppBarTheme(toolbarHeight: 0, elevation: 0),
      ),
      child: Navigator(
        key: ValueKey('settings_$_selectedIndex'),
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => page),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: _logout,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.logout, size: 20, color: Color(0xFFF44336)),
              SizedBox(width: 12),
              Text('退出登录', style: TextStyle(fontSize: 14, color: Color(0xFFF44336))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    context.read<WsClient>().disconnect();
    await context.read<SessionCubit>().deactivate();
    if (!mounted) return;
    context.go('/login');
  }
}

/// 菜单项数据
class _MenuItem {
  final IconData icon;
  final String label;
  const _MenuItem({required this.icon, required this.label});
}

/// 外部链接占位页面
class _ExternalLinkPlaceholder extends StatelessWidget {
  final String title;
  final String hint;
  const _ExternalLinkPlaceholder({required this.title, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_in_browser, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(hint, style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
        ],
      ),
    );
  }
}
