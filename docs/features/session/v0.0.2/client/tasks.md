# session v0.0.2 — 客户端任务清单

基于 [design.md](./design.md) 设计，新增用户资料编辑、密码管理拆分、默认头像渲染，并将 flash_session 重构为三层架构。

---

## 执行顺序

1. ✅ 任务 1 — User 模型更新
2. ✅ 任务 2 — SessionRepository 新增接口 + 路径迁移
3. ✅ 任务 3 — SessionCubit 新增方法
4. ✅ 任务 4 — IdenticonPainter 默认头像组件
5. ✅ 任务 5 — UserAvatar + UserCard 封装
6. ✅ 任务 6 — ProfilePage 改造
7. ✅ 任务 7 — EditProfilePage（即时保存）
8. ✅ 任务 8 — SetPasswordPage 改造
9. ✅ 任务 9 — ChangePasswordPage 新增
10. ✅ 任务 10 — 模块三层架构重构
11. ✅ 任务 11 — 编译验证

---

## 任务 1：User 模型更新 ✅

文件：`flash_session/lib/src/data/user.dart`

- 新增 `signature` 字段，默认空字符串，兼容旧缓存
- 新增 `hasCustomAvatar` getter：`!avatar.startsWith('identicon:')`
- 新增 `identiconSeed` getter：提取 seed 部分
- 更新 `fromJson` / `toJson`，signature 兼容 null

---

## 任务 2：SessionRepository 新增接口 ✅

文件：`flash_session/lib/src/data/session_repository.dart`

- `setPassword` 路径从 `/auth/password` 改为 `/user/password`
- 新增 `updateProfile({nickname?, signature?, avatar?})`：PUT `/user/profile`，返回完整 User
- 新增 `changePassword({oldPassword, newPassword})`：PUT `/user/password`

---

## 任务 3：SessionCubit 新增方法 ✅

文件：`flash_session/lib/src/logic/session_cubit.dart`

- 新增 `updateProfile`：调接口 → 更新状态 + 缓存
- 新增 `changePassword`：调接口，无需更新状态

---

## 任务 4：IdenticonPainter 默认头像组件 ✅

文件：`flash_session/lib/src/view/widget/identicon_avatar.dart`

- `IdenticonPainter`：CustomPainter，DJB2 哈希生成 16 字节，5×5 网格左 3 列决定填充，右 2 列镜像对称，15% 内边距
- `IdenticonAvatar`：ClipRRect + CustomPaint 封装，支持 size / borderRadius 参数
- barrel file 导出 `IdenticonAvatar`

---

## 任务 5：UserAvatar + UserCard 封装 ✅

文件：`flash_session/lib/src/view/widget/user_card.dart`

- `UserAvatar`：根据 User 状态自动渲染 identicon / 网络图片 / 灰色占位
- `UserCard`：微信风格用户卡片（头像 + 昵称 + 闪讯号 + 签名 + 右箭头），支持 onTap
- barrel file 导出 `UserCard`、`UserAvatar`

---

## 任务 6：ProfilePage 改造 ✅

文件：`client/lib/src/home/profile/profile_page.dart`（留在主工程）

- 顶部使用 `UserCard` 组件，点击跳转 EditProfilePage
- 状态栏白色，与卡片背景一致
- 密码行根据 hasPassword 跳转 SetPasswordPage 或 ChangePasswordPage
- 退出登录 → deactivate → go('/login')

---

## 任务 7：EditProfilePage（即时保存）✅

文件：`flash_session/lib/src/view/edit_profile_page.dart`

- `StatelessWidget`，BlocBuilder 驱动数据
- 三组白色卡片分组：头像+名字 | 手机号+闪讯号 | 签名
- 标签固定 72 宽度，w600 加粗，内容右对齐
- 手机号脱敏：前 3 后 2，中间为 *
- 名字、签名：点击跳转 `_TextEditPage` 子页面，点"完成"直接调 `updateProfile` 保存
- 头像：点击跳转 `_AvatarEditPage`，预览大图 120px + "随机更换"按钮 + 点"完成"保存
- AppBar 白色背景

---

## 任务 8：SetPasswordPage 改造 ✅

文件：`flash_session/lib/src/view/set_password_page.dart`

- 移除 `hasPassword` 参数
- 标题固定"设置密码"，提示"为账号设置一个密码"
- 单一输入框，至少 6 位，调用 `setPassword`

---

## 任务 9：ChangePasswordPage 新增 ✅

文件：`flash_session/lib/src/view/change_password_page.dart`

- 旧密码 + 新密码两个输入框
- 调用 `changePassword`，区分 401（旧密码错误）和其他错误
- 样式与 SetPasswordPage 一致

---

## 任务 10：模块三层架构重构 ✅

将 flash_session 从扁平结构重构为 `data/` + `logic/` + `view/` 三层，与 flash_auth 保持一致：

```
flash_session/lib/src/
├── data/       # session_repository.dart, user.dart
├── logic/      # session_cubit.dart, session_state.dart
└── view/       # edit_profile_page, set_password_page, change_password_page
    └── widget/ # identicon_avatar.dart, user_card.dart
```

- 更新所有内部 import 路径
- 更新 barrel file 导出路径
- pubspec.yaml 新增 oktoast 依赖

---

## 任务 11：编译验证 ✅

- `flutter analyze` 零 error（项目自身代码）
- 所有 info/warning 均来自 playground 或 docs/ref 参考项目
