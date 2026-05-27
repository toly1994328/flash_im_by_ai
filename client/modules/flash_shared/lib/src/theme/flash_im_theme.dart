import 'package:flutter/material.dart';

/// 闪讯 IM 调色主题扩展
///
/// 通过 ThemeExtension 注入，统一管理 IM 相关的颜色配置。
/// 使用方式：`Theme.of(context).extension<FlashImTheme>()!.sidebarColor`
class FlashImTheme extends ThemeExtension<FlashImTheme> {
  /// 主色（按钮、链接、选中态）
  final Color primary;

  /// 侧边栏背景色
  final Color sidebarColor;

  /// 搜索栏/标题栏背景色
  final Color headerColor;

  /// 页面背景色
  final Color scaffoldColor;

  /// 会话激活高亮色
  final Color activeConversationColor;

  /// 分割线颜色
  final Color dividerColor;

  /// 输入框背景色
  final Color inputBackgroundColor;

  /// 导航图标选中背景色
  final Color navActiveColor;

  const FlashImTheme({
    required this.primary,
    required this.sidebarColor,
    required this.headerColor,
    required this.scaffoldColor,
    required this.activeConversationColor,
    required this.dividerColor,
    required this.inputBackgroundColor,
    required this.navActiveColor,
  });

  /// 默认亮色主题
  static const light = FlashImTheme(
    primary: Color(0xFF3B82F6),
    sidebarColor: Color(0xFFEAEBF0),
    headerColor: Color(0xFFEAEBF0),
    scaffoldColor: Color(0xFFF5F5F5),
    activeConversationColor: Color(0xFFE8F0FE),
    dividerColor: Color(0xFFF0F0F0),
    inputBackgroundColor: Color(0xFFF8F8F8),
    navActiveColor: Color(0x223B82F6),
  );

  @override
  FlashImTheme copyWith({
    Color? primary,
    Color? sidebarColor,
    Color? headerColor,
    Color? scaffoldColor,
    Color? activeConversationColor,
    Color? dividerColor,
    Color? inputBackgroundColor,
    Color? navActiveColor,
  }) {
    return FlashImTheme(
      primary: primary ?? this.primary,
      sidebarColor: sidebarColor ?? this.sidebarColor,
      headerColor: headerColor ?? this.headerColor,
      scaffoldColor: scaffoldColor ?? this.scaffoldColor,
      activeConversationColor: activeConversationColor ?? this.activeConversationColor,
      dividerColor: dividerColor ?? this.dividerColor,
      inputBackgroundColor: inputBackgroundColor ?? this.inputBackgroundColor,
      navActiveColor: navActiveColor ?? this.navActiveColor,
    );
  }

  @override
  FlashImTheme lerp(ThemeExtension<FlashImTheme>? other, double t) {
    if (other is! FlashImTheme) return this;
    return FlashImTheme(
      primary: Color.lerp(primary, other.primary, t)!,
      sidebarColor: Color.lerp(sidebarColor, other.sidebarColor, t)!,
      headerColor: Color.lerp(headerColor, other.headerColor, t)!,
      scaffoldColor: Color.lerp(scaffoldColor, other.scaffoldColor, t)!,
      activeConversationColor: Color.lerp(activeConversationColor, other.activeConversationColor, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      inputBackgroundColor: Color.lerp(inputBackgroundColor, other.inputBackgroundColor, t)!,
      navActiveColor: Color.lerp(navActiveColor, other.navActiveColor, t)!,
    );
  }
}

/// 便捷扩展：从 context 获取 FlashImTheme
extension FlashImThemeX on BuildContext {
  FlashImTheme get imTheme =>
      Theme.of(this).extension<FlashImTheme>() ?? FlashImTheme.light;
}
