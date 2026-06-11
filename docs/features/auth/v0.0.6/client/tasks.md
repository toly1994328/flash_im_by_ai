# iOS 合规 — 前端任务清单

基于 client/design.md 设计，列出需要创建/修改的具体细节。

**全局约束**：
- 状态管理使用 Cubit，不使用 Event 模式
- 日志使用 `fx_logger`，禁止 `print`
- 变量声明显式标注类型
- async 操作后使用 BuildContext 前必须检查 mounted

---

## 执行顺序

1. ⬜ 任务 1 — MenuAction 加 report 枚举值
2. ⬜ 任务 2 — report_sheet.dart 举报原因选择 UI
3. ⬜ 任务 3 — chat_page.dart 处理 report action
4. ⬜ 任务 4 — block_repository.dart 拉黑/举报 API 调用
5. ⬜ 任务 5 — user_profile_page.dart 加「举报」「拉黑」按钮
6. ⬜ 任务 6 — private_chat_info_page.dart 加「举报」「拉黑」入口
7. ⬜ 任务 7 — block_list_page.dart 黑名单页面
8. ⬜ 任务 8 — settings_page.dart 加「黑名单」入口 + 修改注销逻辑
9. ⬜ 任务 9 — delete_account_page.dart 注销账号独立页面
10. ⬜ 任务 10 — 用户协议补充 UGC 条款
11. ⬜ 任务 11 — 编译验证 + 手动测试

---

## 任务 1：MenuAction 加 report `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/message_action_menu.dart`（修改）

### 1.1 枚举加值 `⬜`

```dart
enum MenuAction { ..., report }
```

### 1.2 getActions 中加入 report `⬜`

在所有消息类型（非系统、非撤回）的菜单末尾加 `MenuAction.report`。

### 1.3 _actionInfo 加映射 `⬜`

```dart
MenuAction.report => (Icons.flag_outlined, '举报'),
```

### 1.4 desktop_context_menu.dart 同步 `⬜`

`DesktopContextMenu._actionInfo` 中加同样的映射。

---

## 任务 2：report_sheet.dart — 举报原因选择 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/report_sheet.dart`（新建）

### 2.1 ReportReason 枚举 `⬜`

```dart
enum ReportReason {
  pornography(0, '色情低俗'),
  violence(1, '暴力恐怖'),
  harassment(2, '骚扰辱骂'),
  fraud(3, '诈骗信息'),
  other(4, '其他');

  final int value;
  final String label;
  const ReportReason(this.value, this.label);
}
```

### 2.2 ReportSheet Widget `⬜`

- StatefulWidget，显示为 BottomSheet（移动端）或 Dialog（桌面端）
- 五个 RadioListTile 选择原因
- 可选的 TextField 补充描述
- 「提交」按钮 → 调用 onSubmit 回调
- 静态 `show` 方法封装 showModalBottomSheet / showDialog

签名：
```dart
class ReportSheet extends StatefulWidget {
  final String targetId;
  final int targetType; // 0=消息, 1=用户
  final Future<void> Function(int reason, String? description) onSubmit;
}
```

---

## 任务 3：chat_page.dart 处理 report action `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/chat_page.dart`（修改）

### 3.1 _handleMenuAction 加 case `⬜`

```dart
case MenuAction.report:
  _reportMessage(context, msg);
```

### 3.2 _reportMessage 方法 `⬜`

```dart
void _reportMessage(BuildContext context, Message msg) {
  ReportSheet.show(
    context: context,
    targetId: msg.id,
    targetType: 0,
    onSubmit: (reason, description) async {
      await context.read<MessageRepository>().dio.post('/api/reports', data: {
        'target_type': 0,
        'target_id': msg.id,
        'reason': reason,
        'description': ?description,
      });
    },
  );
}
```

### 3.3 第二处 switch（移动端长按）同步加 case `⬜`

---

## 任务 4：block_repository.dart — API 调用 `⬜ 待处理`

文件：`client/modules/flash_im_friend/lib/src/data/block_repository.dart`（新建）

### 4.1 BlockRepository 类 `⬜`

```dart
class BlockRepository {
  final Dio _dio;
  BlockRepository({required Dio dio}) : _dio = dio;

  /// 举报用户/消息
  Future<void> report({required int targetType, required String targetId, required int reason, String? description});

  /// 拉黑用户
  Future<void> blockUser(int blockedId);

  /// 取消拉黑
  Future<void> unblockUser(int blockedId);

  /// 获取黑名单
  Future<List<BlockedUser>> getBlockList();

  /// 检查是否已拉黑
  Future<bool> isBlocked(int userId);
}
```

### 4.2 BlockedUser 模型 `⬜`

```dart
class BlockedUser {
  final String userId;
  final String nickname;
  final String? avatar;
  final DateTime blockedAt;

  factory BlockedUser.fromJson(Map<String, dynamic> json);
}
```

---

## 任务 5：user_profile_page.dart 加按钮 `⬜ 待处理`

文件：`client/modules/flash_im_friend/lib/src/view/user_profile_page.dart`（修改）

### 5.1 底部加「举报」「拉黑」按钮 `⬜`

在页面底部或 AppBar 的 actions（「...」PopupMenuButton）中加：
- 「举报该用户」→ 调 ReportSheet.show(targetType: 1, targetId: userId)
- 「拉黑」/ 「取消拉黑」→ 调 BlockRepository

### 5.2 状态判断 `⬜`

进入页面时调 `blockRepo.isBlocked(userId)` 判断按钮文案。

---

## 任务 6：private_chat_info_page.dart 加入口 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/private_chat_info_page.dart`（修改）

### 6.1 底部加操作区 `⬜`

加一个 ListTile 区域：
- 「举报」→ ReportSheet.show(targetType: 1, targetId: peerUserId)
- 「拉黑」→ 确认弹窗 → blockRepo.blockUser

---

## 任务 7：block_list_page.dart — 黑名单页 `⬜ 待处理`

文件：`client/lib/src/home/profile/block_list_page.dart`（新建）

### 7.1 页面结构 `⬜`

- AppBar: "黑名单"
- ListView: 已拉黑用户列表（头像 + 昵称 + 「取消拉黑」按钮）
- 空状态提示

### 7.2 数据加载 `⬜`

initState 时调 `blockRepo.getBlockList()`。

### 7.3 取消拉黑 `⬜`

点击「取消拉黑」→ 确认弹窗 → unblockUser → 刷新列表。

---

## 任务 8：settings_page.dart 修改 `⬜ 待处理`

文件：`client/lib/src/home/profile/settings_page.dart`（修改）

### 8.1 加「黑名单」入口 `⬜`

在「注销账号」上方加一行：
```dart
_buildItem(icon: Icons.block, label: '黑名单', onTap: () => Navigator.push(...BlockListPage...))
```

### 8.2 修改「注销账号」行为 `⬜`

将 `_confirmDeleteAccount` 改为跳转 `DeleteAccountPage`：
```dart
_buildItem(icon: Icons.delete_outline, label: '注销账号', onTap: () => Navigator.push(...DeleteAccountPage...))
```

删除旧的 `_confirmDeleteAccount` 方法。

---

## 任务 9：delete_account_page.dart — 注销页 `⬜ 待处理`

文件：`client/lib/src/home/profile/delete_account_page.dart`（新建）

### 9.1 页面结构 `⬜`

- AppBar: "注销账号"
- 注销须知文本（⚠️ 标注不可恢复内容）
- 密码输入框
- 「确认注销」按钮（红色）

### 9.2 提交逻辑 `⬜`

1. 校验密码非空
2. POST /api/account/delete { password }
3. 成功 → 清除本地数据（localStore.clearAll + sessionCubit.logout）→ 跳转登录页
4. 401 → 提示"密码错误"
5. 400 → 提示"请先设置密码"并跳转设置密码页

---

## 任务 10：用户协议补充 UGC 条款 `⬜ 待处理`

文件：服务端静态文件 `server/static/policy/user-agreement.html`（修改或新建）

### 10.1 补充 UGC 相关条款 `⬜`

在用户协议中增加：
- 禁止发布色情/暴力/骚扰/诈骗等不当内容
- 平台有权在收到举报后 24 小时内处理
- 违规用户将被移除内容并封禁账号
- 用户可通过应用内举报功能反馈不当内容

### 10.2 确认登录页底部展示 `⬜`

确认 `flash_auth/login_page.dart` 底部的协议链接可正常打开且包含 UGC 条款。

---

## 任务 11：编译验证 + 手动测试 `⬜ 待处理`

### 11.1 flutter analyze `⬜`

```bash
cd client
flutter analyze --no-fatal-infos
```

### 11.2 手动验证路径 `⬜`

1. 长按消息 → 菜单出现「举报」→ 选原因 → 提交 → toast
2. 右键消息（桌面端）→「举报」→ 同上
3. 用户资料页 → 「...」→ 举报 / 拉黑
4. 设置 → 黑名单 → 列表 → 取消拉黑
5. 设置 → 注销账号 → 须知页 → 输密码 → 确认 → 退出到登录页
6. 登录页底部 → 点击用户协议 → 包含 UGC 条款

### 11.3 录屏准备 `⬜`

在物理设备（iPad）上录制：
1. EULA 展示（注册/登录页底部协议）
2. 举报流程（长按消息 → 举报 → 选原因 → 提交）
3. 拉黑流程（资料页 → 拉黑 → 确认）
