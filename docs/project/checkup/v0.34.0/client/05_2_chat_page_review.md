# chat_page.dart 代码评审

日期：2026-06-14　版本：v0.34.0（handler 拆分 + 参数重构后）

当前行数：730 行

---

## 问题清单

| # | 维度 | 问题描述 | 严重度 | 建议 |
|---|------|---------|--------|------|
| 1 | 结构 | build 方法约 130 行，含 3 层 BlocBuilder 嵌套 | P0 | 拆为 `_buildInputSection`、`_buildDisbandBar` 子方法 |
| 2 | 结构 | `_buildMessageList` 约 100 行，itemBuilder 内计算+构建混杂 | P0 | itemBuilder 提取为独立方法 `_buildMessageItem` |
| 3 | 可读性 | ChatInput / ChatInputDesktop 共享 6 个相同参数重复传递 | P1 | 提取 `_buildChatInput(ChatCubit)` 统一处理 |
| 4 | 可读性 | `_safeSend(context, () => cubit.xxx(path))` 每个发送回调都包裹 | P1 | 重命名为 `_trySend`，去掉多余 context 参数；或下沉到 Cubit |
| 5 | 可读性 | `_buildMultiSelectBar` 35 行，是可独立构建的小零件 | P1 | 提取为独立文件 `chat_multi_select_bar.dart` |
| 6 | 可读性 | `_buildSkeleton` 30 行，纯展示组件 | P1 | 提取为独立文件 `chat_skeleton.dart` |
| 7 | 分层 | `_fetchGroupMembers` 直接 `dio.get(...)` | P1 | 下沉到 Repository 或 Cubit |
| 8 | 分层 | `_loadGroupDetail` 解析 `detail['status']` JSON | P2 | groupDetailFetcher 返回强类型或由 Cubit 处理 |
| 9 | 命名 | `_handleAvatarTap` 只是 `_openUserProfile` 的纯委托 | P2 | 直接传 `_openUserProfile` |
| 10 | 命名 | `_opts` 缩写不够自解释 | P2 | 改为直接 `widget.viewOptions` 或 `_viewOptions` |
| 11 | 组件分离 | 多选复选框行（AnimatedContainer + AnimatedSwitcher）30+ 行 | P2 | 提取为 `SelectableMessageRow` Widget |
| 12 | 性能 | itemBuilder 内每次 `context.read<ChatCubit>()` 读 2 次 | P2 | 提到 itemBuilder 外或传入参数 |

---

## 改进方案

### P0：build 方法拆分

将 build 按 UI 区域拆为子方法，使骨架一屏可见：

```dart
@override
Widget build(BuildContext context) {
  return AnnotatedRegion<SystemUiOverlayStyle>(
    value: _systemOverlayStyle,
    child: Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_showAnnouncement) AnnouncementBanner(...),
          _buildPinnedBar(),
          Expanded(child: _buildMessageArea()),
          _isDisband ? _buildDisbandBar() : _buildInputSection(),
        ],
      ),
    ),
  );
}
```

每个子方法 10~30 行，build 本身降到 20 行。

### P0：itemBuilder 提取

```dart
Widget _buildMessageItem(Message msg, ChatCubit cubit, ChatState state) {
  final bool isMe = msg.senderId == cubit.currentUserId;
  // ... 构建 bubble + 多选行
}
```

`_buildMessageList` 只保留 ListView.builder 框架 + shrinkWrap 逻辑，降到 30 行。

---

### P1：输入区统一

```dart
Widget _buildChatInput(ChatCubit cubit) {
  if (_opts.embedded) {
    return ChatInputDesktop(...共同参数...);
  }
  return ChatInput(...共同参数..., onSendVideo: _handleSendVideo, ...);
}
```

消除 6 个参数的重复。

### P1：`_safeSend` → `_trySend`

```dart
Future<void> _trySend(Future<void> Function() action) async {
  try {
    await action();
  } on FileSizeExceedException catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  }
}
```

去掉冗余 `context` 参数，名字表达"尝试发送可能失败"。

### P1：组件文件分离

```
view/
├── chat_page.dart            # 主页面骨架（目标 ~350 行）
├── chat_page_config.dart     # ChatTarget + ChatViewOptions
├── chat_app_bar.dart         # AppBar
├── announcement_banner.dart  # 公告横幅
├── components/               # 按功能收录小组件
│   ├── chat_multi_select_bar.dart
│   ├── chat_skeleton.dart
│   └── selectable_message_row.dart
```

### P1：`_fetchGroupMembers` 下沉

移到 `MessageRepository` 或 `ChatCubit`，View 层只调用 `cubit.loadGroupMembers()`。

---

### P2（一行带过）

- `_handleAvatarTap` 删除，直接传 `_openUserProfile`
- `_opts` 改为 `_viewOptions`
- `_loadGroupDetail` JSON 解析改为强类型返回
- itemBuilder 中 `context.read<ChatCubit>()` 提到外层

---

## 执行优先级

| 顺序 | 内容 | 状态 |
|------|------|------|
| 1 | ✅ handler 拆分（ChatMediaHandler + ChatMenuHandler） | 完成 |
| 2 | ✅ AppBar 独立组件 | 完成 |
| 3 | ✅ 参数重构（ChatTarget + ChatViewOptions） | 完成 |
| 4 | ✅ _safeSend 消除 → ShowToastEvent 事件总线 | 完成 |
| 5 | ✅ WS listener 提取为命名方法 | 完成 |
| 6 | ✅ AnnouncementBanner 独立文件 | 完成 |
| 7 | ✅ PinnedScope 独立（pinned/ 文件夹） | 完成 |
| 8 | ✅ _handleAvatarTap 删除、onImageTap 归 mediaHandler | 完成 |
| 9 | ✅ _isGroup getter、_showAnnouncement getter | 完成 |
| 10 | 🔲 ChatGroupCubit 拆分（群组状态下沉 logic 层） | 下一步 |
| 11 | 🔲 MentionMember 移到 data 层（已创建文件） | 下一步 |
| 12 | 🔲 输入区 Scope 化 / _buildChatInput 提取 | 待定 |
| 13 | 🔲 _buildMessageList itemBuilder 提取 | 待定 |
| 14 | 🔲 MultiSelectBar / Skeleton 独立文件 | 待定 |

## 下一步：ChatGroupCubit 拆分

### 已完成准备
- `chat_group_cubit.dart` 已创建（logic 层）
- `mention_member.dart` 已创建（data 层）
- `mention_picker.dart` 已改为 export data 层

### 待执行
1. chat_page.dart 移除：`_title`、`_isDisband`、`_announcement`、`_groupMembers`、`_groupInfoSub`、`_loadGroupDetail`、`_loadGroupMembers`、`_fetchGroupMembers`、`_onGroupInfoUpdate`、`_showAnnouncement`
2. chat_page.dart 中通过 `context.select((ChatGroupCubit c) => c.state.xxx)` 获取群组数据
3. home_actions_mixin.dart 注入 `BlocProvider<ChatGroupCubit>`
4. ChatAppBar 从 ChatGroupCubit 获取 title / isDisband
5. AnnouncementBanner 从 ChatGroupCubit 获取 announcement
