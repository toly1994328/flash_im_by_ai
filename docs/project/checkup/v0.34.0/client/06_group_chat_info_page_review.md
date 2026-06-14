# group_chat_info_page.dart 代码评审

日期：2026-06-14　版本：v0.34.0

当前行数：881 行

---

## 问题清单

| # | 维度 | 问题描述 | 严重度 | 建议 |
|---|------|---------|--------|------|
| 1 | 结构 | 881 行 God Widget，方法 20+ 个 | P0 | 按 UI 区域拆为独立 Widget 文件 |
| 2 | 分层 | View 层直接调 `repository.xxx()` + 手动 setState 管理状态 | P0 | 提取 Cubit 管理群详情加载/操作 |
| 3 | 可读性 | 6 个业务操作方法（邀请/踢人/转让/解散/退出/改名）硬嵌 State 中 | P0 | 提取 Handler 或移入 Cubit |
| 4 | 组件分离 | `_buildMemberSection` 90 行 + `_buildMemberTile` 40 行 | P1 | 独立为 `group_member_grid.dart` |
| 5 | 组件分离 | `_buildSettingItem` / `_buildSwitchItem` / `_buildActionButton` 通用 UI | P1 | 独立为 `group_setting_widgets.dart` |
| 6 | 组件分离 | `_DashedBorderPainter` 50 行 | P1 | 独立为 `dashed_border_painter.dart` |
| 7 | 可读性 | `_detail` 是 `Map<String, dynamic>?`，到处 `as String?`、`as int?` | P1 | 定义强类型 `GroupDetail` 数据类 |
| 8 | 可读性 | 每个操作方法都有 try-catch + SnackBar 重复模式 | P1 | 统一用 ShowToastEvent 或 Cubit error state |
| 9 | 命名 | `_load`、`_detail`、`_error` 太泛 | P2 | `_loadDetail`、`_groupDetail`、`_loadError` |
| 10 | 性能 | `_resolveUrl` 每次调用重复判断 | P2 | 加载时一次性解析存入强类型模型 |

---

## 改进方向

### P0：架构拆分

1. **GroupInfoCubit** — 管理群详情加载、设置切换、成员操作（邀请/踢人/转让/解散/退出/改名）
2. **页面骨架** — `group_chat_info_page.dart` 只做 UI 组装，通过 Cubit 获取数据
3. **操作方法下沉** — 6 个业务方法全部移入 Cubit，失败时 emit ShowToastEvent

### P1：组件独立化

```
flash_im_group/lib/src/view/group_info/
├── group_chat_info_page.dart       # 主页面骨架（~200 行）
├── group_member_grid.dart          # 成员网格区域
├── group_setting_section.dart      # 设置项区域（群名/群号/公告/验证）
├── group_action_section.dart       # 底部操作按钮（退群/解散/转让）
└── dashed_border_painter.dart      # 虚线边框绘制器
```

### P1：强类型数据

```dart
class GroupDetail {
  final String name;
  final int groupNo;
  final String? avatar;
  final String? announcement;
  final String ownerId;
  final bool joinVerification;
  final List<GroupMember> members;
}
```

加载时一次性解析，消除所有 `as String?` / `as int?`。
