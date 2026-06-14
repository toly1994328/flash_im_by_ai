# group_chat_info_page.dart 重构计划

日期：2026-06-14　版本：v0.34.0

来源：`06_group_chat_info_page_review.md` 评审清单

---

## 目标

881 行 → ~250 行（主页面骨架），业务逻辑下沉 Cubit，UI 组件独立文件。

---

## 步骤清单

### Step 1：提取强类型数据类

**手法**：提取值对象

**产出**：`data/group_detail.dart`

```dart
class GroupDetail {
  final String name;
  final int groupNo;
  final String? avatar;
  final String? announcement;
  final String ownerId;
  final bool joinVerification;
  final List<GroupMember> members;
  final int status; // 0=正常, 1=已解散
}

class GroupMember {
  final String userId;
  final String nickname;
  final String? avatar;
}
```

`GroupRepository.getGroupDetail` 返回 `GroupDetail` 而非 `Map<String, dynamic>`。

---

### Step 2：提取 GroupInfoCubit

**手法**：提取 Cubit

**产出**：`logic/group_info_cubit.dart`

**State**：
```dart
sealed class GroupInfoState {}
class GroupInfoLoading extends GroupInfoState {}
class GroupInfoError extends GroupInfoState { final String message; }
class GroupInfoLoaded extends GroupInfoState { final GroupDetail detail; }
```

**Cubit 方法**：
- `loadDetail()` — 加载群详情
- `toggleJoinVerification(bool)` — 切换入群验证
- `inviteMembers(List<int>)` — 邀请入群
- `removeMember(int)` — 踢人
- `transferOwner(int)` — 转让群主
- `disbandGroup()` — 解散群聊
- `leaveGroup()` — 退出群聊
- `updateGroupName(String)` — 修改群名

所有操作失败时 emit `ShowToastEvent`，成功后自动 `loadDetail()` 刷新。

---

### Step 3：提取成员网格组件

**手法**：提取独立 Widget 文件

**产出**：`view/group_info/group_member_grid.dart`

**参数**：
```dart
class GroupMemberGrid extends StatelessWidget {
  final List<GroupMember> members;
  final String? ownerId;
  final bool isOwner;
  final String? baseUrl;
  final VoidCallback onInvite;
  final VoidCallback? onRemove; // 仅群主
}
```

内含 `_buildMemberTile`、`_buildActionTile`、展开/收起逻辑。

---

### Step 4：提取设置区组件

**手法**：提取独立 Widget 文件

**产出**：`view/group_info/group_setting_section.dart`

封装 `_buildSettingItem`、`_buildSwitchItem`、`_buildDivider` 为独立组件：

```dart
class SettingItem extends StatelessWidget { ... }
class SwitchItem extends StatelessWidget { ... }
```

---

### Step 5：提取操作按钮区

**手法**：提取独立 Widget 文件

**产出**：`view/group_info/group_action_section.dart`

```dart
class GroupActionSection extends StatelessWidget {
  final bool isOwner;
  final VoidCallback onTransfer;
  final VoidCallback onDisband;
  final VoidCallback onLeave;
}
```

---

### Step 6：提取 DashedBorderPainter

**手法**：提取独立 Widget 文件

**产出**：`view/group_info/dashed_border_painter.dart`

纯绘制逻辑，无业务耦合。

---

### Step 7：重写主页面骨架

**主页面只做组装**：

```dart
/// 群聊详情页。
///
/// ## 页面结构
///
/// ```
/// ┌─────────────────────────────┐
/// │  AppBar                     │
/// ├─────────────────────────────┤
/// │  GroupMemberGrid            │  成员网格
/// ├─────────────────────────────┤
/// │  SettingSection             │  群头像/群名/群号/公告/搜索
/// ├─────────────────────────────┤
/// │  SwitchItem (群主)          │  入群验证
/// ├─────────────────────────────┤
/// │  GroupActionSection         │  转让/解散/退出
/// └─────────────────────────────┘
/// ```
///
/// ## 状态来源
///
/// - [GroupInfoCubit] — 群详情加载与操作
class GroupChatInfoPage extends StatelessWidget { ... }
```

注意：有了 Cubit 后，页面可以变成 StatelessWidget。

---

### Step 8：目录组织

```
flash_im_group/lib/src/
├── data/
│   └── group_detail.dart           # [新增] 强类型数据类
├── logic/
│   └── group_info_cubit.dart       # [新增] 群详情状态管理
└── view/
    ├── group_info/                  # [新增] 群详情页文件夹
    │   ├── group_chat_info_page.dart    # 主页面骨架（~250 行）
    │   ├── group_member_grid.dart       # 成员网格
    │   ├── group_setting_section.dart   # 设置项
    │   ├── group_action_section.dart    # 底部操作按钮
    │   └── dashed_border_painter.dart   # 虚线边框绘制器
    ├── create_group_page.dart
    ├── edit_group_name_page.dart
    └── group_announcement_page.dart
```

---

### Step 9：编译验证 + 总结

- `dart analyze lib` 零错误（flash_im_group 模块）
- `dart analyze lib` 零错误（client 全量）
- 输出总结到 `docs/project/checkup/v0.34.0/client/06_2_group_chat_info_refactor_summary.md`

---

## 执行顺序依赖

```
Step 1 (数据类) → Step 2 (Cubit) → Step 3~6 (组件) → Step 7 (主页面) → Step 8 (目录) → Step 9 (验证)
```

Step 1 和 Step 2 有强依赖（Cubit 需要强类型），Step 3~6 之间无依赖可并行。

---

## 预估效果

| 文件 | 预计行数 | 职责 |
|------|----------|------|
| group_chat_info_page.dart | ~250 | 纯 UI 组装 |
| group_info_cubit.dart | ~150 | 状态管理 + 操作 |
| group_member_grid.dart | ~130 | 成员网格 |
| group_setting_section.dart | ~80 | 设置项 |
| group_action_section.dart | ~40 | 操作按钮 |
| dashed_border_painter.dart | ~50 | 绘制器 |
| group_detail.dart | ~40 | 数据类 |
| **合计** | **~740** | — |

原始 881 行 → 分布到 7 个文件约 740 行，每个文件职责单一、可独立迭代。
