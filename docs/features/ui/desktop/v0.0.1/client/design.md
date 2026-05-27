---
module: desktop
version: v0.26.0
date: 2026-05-27
tags: [macOS, 桌面端, 自适应布局, 分栏, Rx$]
---

# 桌面端 UI 适配 — 前端设计报告

> 关联设计：[desktop v0.26.0 analysis](../analysis.md)

## 1. 目标

- 引入响应式布局系统（`tolyui_rx_layout` + `Rx$`），根据窗口宽度自动切换桌面端/移动端布局
- 桌面端消息 Tab 使用三栏布局：侧边导航 + 会话列表 + 聊天区
- 桌面端通讯录/设置使用两栏布局：侧边导航 + 内容占满
- 移动端保持现有布局不变
- 组件通过参数控制样式（`embedded`），不依赖平台检测

## 2. 现状分析

### 已有能力

- HomePage 使用 IndexedStack + 底部导航栏
- ConversationListPage 支持 `onConversationTap` 回调
- ChatPage 接收参数独立渲染
- 所有业务逻辑在 Cubit 层，与 UI 布局解耦

### 存在的问题（已解决）

- 纯移动端设计 → 引入 `Rx$` 响应式切换
- 所有页面全屏跳转 → 桌面端嵌入面板
- ChatPage 只有全屏模式 → 新增 `embedded` 参数
- 输入框不适合桌面端 → 新增 `ChatInputDesktop`

## 3. 响应式布局方案

使用 `tolyui_rx_layout`（1.0.0+2）：

```dart
// HomePage 中一行代码切换布局
Rx$(
  mobile: (_) => MobileLayout(homeState: this),
  desktop: (_) => DesktopLayout(homeState: this),
)
```

断点策略通过 `ReParserStrategyTheme`（ThemeExtension）全局注入。

| 决策 | 理由 |
|------|------|
| 使用 `tolyui_rx_layout` | 5 级断点 + ThemeExtension 配置 |
| `Rx$` 做布局分支 | 只需 mobile/desktop 两档 |
| 组件用 `embedded` 参数 | 不依赖平台检测，纯参数驱动 |

## 4. 核心流程

### 文件拆分（公共块 + 组装）

```
home/view/
├── home_page.dart          — 入口：initState + Rx$ 分发（~100 行）
├── home_actions_mixin.dart — 公共动作 mixin（~220 行）
├── mobile_layout.dart      — 移动端布局组装（~270 行）
└── desktop_layout.dart     — 桌面端布局组装（~180 行）
```

### 桌面端布局结构

```
DesktopLayout
├── Row
│   ├── 侧边导航栏（72px，自定义）
│   │   ├── 头像
│   │   ├── 消息/通讯录/我 图标
│   │   └── 底部设置按钮
│   └── 内容区（Expanded）
│       ├── navIndex==0 → Row（三栏）
│       │   ├── 会话列表（320px）
│       │   └── 聊天区（Expanded，ChatPage embedded）
│       ├── navIndex==1 → 通讯录（占满）
│       ├── navIndex==2 → ProfilePage（占满）
│       └── navIndex==3 → SettingsPage（占满）
```

### ChatPage embedded 模式

```dart
ChatPage(
  embedded: true,  // 桌面端面板内
  // embedded=true 时：
  // - 白色 AppBar，标题 14px 居左
  // - 无返回按钮
  // - AppBar 支持拖拽移动窗口
  // - 底部分割线
  // - 使用 ChatInputDesktop
)
```

## 5. 技术决策

| 决策 | 方案 | 理由 |
|------|------|------|
| 响应式库 | `tolyui_rx_layout: 1.0.0+2` | 5 级断点 + `Rx$` 便捷组件 |
| 平台检测 | `fx_env: 0.0.1+3`（`kApp.isDesktop`） | 仅用于 main.dart 窗口初始化 |
| 窗口管理 | `window_manager: ^0.4.3` | 窗口大小、标题栏隐藏、拖拽 |
| 组件样式控制 | `embedded` 参数 | 不依赖平台，纯参数驱动 |
| 公共逻辑复用 | mixin（HomeActionsMixin） | 移动端和桌面端共用业务操作 |
| 会话选中高亮 | `activeConversationId` + `isActive` | 默认 null，移动端不受影响 |
| 弹出菜单 | 桌面端白色卡片 / 移动端深色气泡 | `kApp.isDesktop` 区分（仅此组件） |
| 桌面端输入框 | `ChatInputDesktop`（独立文件） | 微信风格：白色圆角框 + 底部工具栏 |
| IM 调色主题 | `FlashImTheme`（ThemeExtension） | 统一管理颜色，便于换肤 |

## 6. 验收标准

| 验收条件 | 验收方式 |
|----------|----------|
| macOS 编译通过 | `flutter build macos --release` |
| 窗口 >= 断点值时显示桌面端布局 | macOS 运行验证 |
| 消息 Tab 三栏布局 | 点击会话右侧显示聊天 |
| 通讯录/设置 两栏布局 | 切换 Tab 验证 |
| 选中会话高亮 | 淡蓝色背景 |
| 侧边栏/搜索栏支持拖拽 | 拖动窗口验证 |
| 移动端布局不受影响 | Android 运行验证 |
| 桌面端输入框微信风格 | 白色圆角框 + Enter 发送 |

## 7. 暂不实现

| 功能 | 理由 |
|------|------|
| 桌面端快捷键 | 后续版本 |
| 窗口最小化到托盘 | 后续版本 |
| 系统级通知弹窗 | 后续版本 |
| 面板宽度可拖拽 | 后续版本 |
| 全局 ChatCubit | 当前用 ValueKey 重建，后续优化 |
