---
name: flash-im-ui-style
description: 闪讯 IM 的 UI 风格与样式规范。在编写 Flutter 页面时激活，确保视觉一致性。
metadata:
  model: manual
  last_modified: Sat, 19 Apr 2026 00:00:00 GMT

---
# 闪讯 UI 风格规范

## Contents
- [Color Palette](#color-palette)
- [AppBar Style](#appbar-style)
- [Page Background](#page-background)
- [List Items](#list-items)
- [Buttons](#buttons)
- [Switch Toggle](#switch-toggle)
- [Avatar](#avatar)
- [Search Bar](#search-bar)
- [Contact Header Items](#contact-header-items)
- [Dialog](#dialog)
- [Toast / SnackBar](#toast--snackbar)
- [Badge](#badge)

## Color Palette

| 用途 | 色值 | 说明 |
|------|------|------|
| 主色 | `#3B82F6` | 蓝色，按钮/链接/选中态 |
| 微信绿 | `#07C160` | Switch 激活色、在线状态 |
| 橙色 | `#FF9800` | 警告/需验证按钮 |
| 红色 | `#F44336` | 删除/退出/错误 |
| 文字主色 | `#333333` | 标题、正文 |
| 文字次色 | `#999999` | 副标题、描述、时间 |
| 文字提示色 | `#BBBBBB` | placeholder、hint |
| 分割线 | `#F0F0F0` | 列表分割线（0.5px） |
| 页面背景 | `#F5F5F5` | Scaffold 背景 |
| AppBar 背景 | `#EDEDED` | 灰色 AppBar（消息/通讯录 Tab） |
| AppBar 背景（白） | `#FFFFFF` | 白色 AppBar（详情页/设置页） |
| 卡片背景 | `#FFFFFF` | 列表项、设置项 |
| 输入框背景 | `#F8F8F8` | TextField 填充色 |

## AppBar Style

两种风格：

**灰色 AppBar**（Tab 页面、搜索页）：
```dart
AppBar(
  title: const Text('标题'),
  backgroundColor: const Color(0xFFEDEDED),
  elevation: 0,
  scrolledUnderElevation: 0,
)
```

**白色 AppBar**（详情页、设置页）：
```dart
AppBar(
  title: const Text('标题'),
  backgroundColor: Colors.white,
  foregroundColor: const Color(0xFF333333),
  elevation: 0,
  scrolledUnderElevation: 0,
)
```

## Page Background

```dart
Scaffold(backgroundColor: const Color(0xFFF5F5F5))
```

白色内容区域用 `Container(color: Colors.white)` 包裹，区域之间用 `SizedBox(height: 10)` 灰色间隔分组。

## List Items

**标准列表项**（好友列表、申请列表）：
- padding: `EdgeInsets.symmetric(horizontal: 16, vertical: 12)`
- 分割线: `Padding(left: 68)` + `Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF0F0F0))`
- 左侧头像 44px，间距 12px

**设置项**（群详情、聊天设置）：
```dart
Container(
  color: Colors.white,
  child: ListTile(
    title: Text(title, style: TextStyle(fontSize: 16, color: Color(0xFF333333))),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
        SizedBox(width: 4),
        Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
      ],
    ),
  ),
)
```

设置项之间的分割线：
```dart
Container(
  color: Colors.white,
  padding: const EdgeInsets.only(left: 16),
  child: const Divider(height: 0.5, thickness: 0.5),
)
```

## Buttons

**操作按钮**（好友申请/群通知的同意/拒绝）：

拒绝（灰色文字）：
```dart
GestureDetector(
  onTap: onReject,
  child: Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Text('拒绝', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
  ),
)
```

同意/接受（蓝色填充）：
```dart
GestureDetector(
  onTap: onAccept,
  child: Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      color: Color(0xFF3B82F6),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text('同意', style: TextStyle(fontSize: 13, color: Colors.white)),
  ),
)
```

**搜索结果按钮**（四种状态）：

| 状态 | 样式 |
|------|------|
| 已加入/已申请 | 灰色背景 `#F0F0F0` + 灰色文字 `#999999` |
| 加入 | 蓝色填充 `#3B82F6` + 白色文字 |
| 申请 | 橙色边框 `#FF9800` + 橙色文字 |

按钮 padding: `EdgeInsets.symmetric(horizontal: 10, vertical: 4)`，borderRadius: 4

## Switch Toggle

[toly+] iOS 风格 CupertinoSwitch，主题蓝激活色：

```dart
SizedBox(
  width: 56,
  height: 32,
  child: FittedBox(
    fit: BoxFit.contain,
    child: CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: const Color(0xFF3B82F6),
    ),
  ),
)
```

需要 `import 'package:flutter/cupertino.dart';`

## Avatar

**通用头像**（AvatarWidget）：
- 默认 size: 44, borderRadius: 6
- 支持 `identicon:seed` 格式（像素风头像）
- 支持 `http://...` 网络图片
- 空值显示灰色占位图标

**群头像**（GroupAvatarWidget）：
- 解析 `grid:url1,url2,...` 格式
- 每行 5 个成员网格，LayoutBuilder 计算 tile 宽度
- 群主角标：橙色 "群主" 标签在头像右下角

```dart
// 群主角标
Positioned(
  right: -2, bottom: -2,
  child: Container(
    padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
    decoration: BoxDecoration(
      color: Colors.orange,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text('群主', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
  ),
)
```

## Search Bar

**占位模式**（点击跳转搜索页）：
```dart
FlashSearchBar(hintText: '搜索', onTap: () => ...)
```

**输入模式**（可编辑）：
```dart
FlashSearchBar(hintText: '搜索', editable: true, controller: ..., onChanged: ...)
```

[toly+] **自定义搜索框**（带右侧 loading 指示器）：
- 搜索时保留已有结果不闪烁
- loading 只在搜索框右侧显示 16×16 的 CircularProgressIndicator
- 背景色 `#EDEDED`，输入框白色圆角 6px

## Contact Header Items

通讯录顶部固定入口（新的朋友、群通知、群聊）：

```dart
// 图标容器
Container(
  width: 40, height: 40,
  decoration: BoxDecoration(
    color: iconColor,  // 橙色/蓝色/绿色
    borderRadius: BorderRadius.circular(6),
  ),
  child: Icon(icon, color: Colors.white, size: 22),
)
```

| 入口 | 图标 | 颜色 |
|------|------|------|
| 新的朋友 | `Icons.person_add` | `#F97D1C` 橙色 |
| 群通知 | `Icons.notifications` | `#3B82F6` 蓝色 |
| 群聊 | `Icons.group` | `#4CAF50` 绿色 |

红点角标：红色圆角背景 + 白色数字，padding `horizontal: 8, vertical: 2`

## Dialog

入群确认/申请对话框：
- `AlertDialog` + `RoundedRectangleBorder(borderRadius: 12)`
- 群信息预览卡片：灰色背景 `#F8F8F8`，圆角 8
- 需验证时显示留言 TextField（maxLines: 2, maxLength: 100）
- 取消按钮：灰色文字 `#999999`
- 确认按钮：`FilledButton` + 圆角 6

## Toast / SnackBar

统一用 `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(...)))`

常见文案：
- 入群成功：`已成功加入群聊`
- 申请已发送：`申请已发送，等待群主审批`
- 审批结果：`已同意` / `已拒绝`
- 设置变更：`已开启入群验证` / `已关闭入群验证`
- 操作失败：`操作失败：$e`

## Badge

红点角标（通讯录 Tab、群通知入口）：
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
  decoration: BoxDecoration(
    color: Colors.red,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(count > 99 ? '99+' : '$count',
      style: TextStyle(color: Colors.white, fontSize: 10)),
)
```


## Shared Components

闪讯的公共组件分布在 `flash_shared` 和 `flash_session` 两个模块中。

### flash_shared（基础 UI 组件）

位置：`client/modules/flash_shared/lib/src/`

| 组件 | 文件 | 用途 |
|------|------|------|
| IdenticonAvatar | identicon_avatar.dart | 像素风头像，基于 seed 生成 5×5 对称方块图案 |
| AvatarWidget | avatar_widget.dart | 通用头像，自动路由 identicon / 网络图片 / 占位 |
| GroupAvatarWidget | group_avatar_widget.dart | 群组宫格头像，解析 grid: 格式，微信风格布局 |
| WxPopupMenuButton | popup_menu_button.dart | 微信风格右上角弹出菜单，深色气泡 + 尖角 + 动画 |
| FlashSearchBar | search_bar.dart | 搜索栏，占位模式 / 编辑模式两种 |
| FlashSearchInput | search_input.dart | 纯搜索输入框，白色圆角 + 搜索图标 |

#### AvatarWidget

```dart
AvatarWidget(
  avatar: 'identicon:user123',  // 或 'http://...' 或 null
  size: 44,
  borderRadius: 6,
)
```

路由规则：
- `identicon:xxx` → IdenticonAvatar（像素风）
- `http(s)://...` → Image.network（含错误降级）
- 空/null → 灰色占位图标

#### GroupAvatarWidget

```dart
GroupAvatarWidget(
  members: [
    GroupAvatarMember(id: '1', avatarUrl: 'identicon:1'),
    GroupAvatarMember(id: '2', avatarUrl: 'identicon:2'),
  ],
  size: 48,
  borderRadius: 6,
)
```

布局规则：1 人铺满、2 人横排、3 人上 1 下 2、4 人 2×2、5-9 人 3 列网格。

解析 `grid:` 格式：
```dart
final avatar = 'grid:url1,url2,url3';
final avatarList = avatar.substring(5).split(',');
final members = avatarList.asMap().entries.map((e) =>
  GroupAvatarMember(id: 'member_${e.key}', avatarUrl: e.value.trim().isNotEmpty ? e.value.trim() : null)
).toList();
```

#### WxPopupMenuButton

```dart
WxPopupMenuButton(
  items: [
    WxMenuItem(icon: Icons.group_add, text: '发起群聊', onTap: () => ...),
    WxMenuItem(icon: Icons.person_add, text: '加好友/群', onTap: () => ...),
  ],
  child: Icon(Icons.add_circle_outline, size: 22),
)
```

深色气泡菜单，缩放 0.8→1.0 + 淡入 200ms 动画，点击背景自动关闭。

#### FlashSearchBar

```dart
// 占位模式（点击跳转）
FlashSearchBar(hintText: '搜索', onTap: () => Navigator.push(...))

// 编辑模式（可输入）
FlashSearchBar(editable: true, controller: ctrl, onChanged: (v) => ...)
```

高度 36px，背景色 `#EDEDED`，输入框白色圆角 6px。

### flash_session（用户相关组件）

位置：`client/modules/flash_session/lib/src/view/`

| 组件 | 文件 | 用途 |
|------|------|------|
| UserAvatar | widget/user_card.dart | 用户头像，基于 User 对象自动选择渲染方式 |
| UserCard | widget/user_card.dart | 微信风格用户卡片（头像 + 昵称 + 闪讯号 + 签名） |
| SetPasswordPage | set_password_page.dart | 设置密码页面 |
| EditProfilePage | edit_profile_page.dart | 个人资料编辑页面 |

#### UserAvatar

```dart
UserAvatar(user: currentUser, size: 64, borderRadius: 8)
```

和 AvatarWidget 的区别：UserAvatar 直接接收 User 对象，根据 `hasCustomAvatar` 自动选择 identicon 或网络图片。AvatarWidget 接收字符串。

### URL 解析规范

头像 URL 可能是相对路径，需要拼接 baseUrl。统一的解析方法：

```dart
String? _resolveUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http') || path.startsWith('identicon:') || path.startsWith('grid:')) return path;
  if (baseUrl != null) return '$baseUrl$path';
  return path;
}
```

注意：`identicon:` 和 `grid:` 前缀不能拼接 baseUrl，否则会变成无效 URL。
