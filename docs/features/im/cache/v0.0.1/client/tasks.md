# 本地缓存与离线同步 — 客户端任务清单

基于 [design.md](design.md) 设计。前端是本次功能的重头戏，新建 flash_im_cache 模块 + 改造三个 Repository + 初始化流程。

架构要点：LocalStore 是抽象接口，DriftLocalStore 是 drift 实现。上层只依赖接口和纯 Dart 模型，不碰 drift。SyncEngine 通过回调通知 Cubit 刷新（参考腾讯 IM SDK 模式）。

---

## 执行顺序

1. ✅ 任务 1 — 创建 flash_im_cache 模块骨架 + 依赖
2. ✅ 任务 2 — 纯 Dart 模型（models/）
3. ✅ 任务 3 — LocalStore 抽象接口
4. ✅ 任务 4 — drift 表定义（tables/）
5. ✅ 任务 5 — AppDatabase + per-user 打开
6. ✅ 任务 6 — 运行 drift 代码生成
7. ✅ 任务 7 — converters（drift 类型 ↔ 纯 Dart 模型）
8. ✅ 任务 8 — MessageDao
9. ✅ 任务 9 — ConversationDao
10. ✅ 任务 10 — FriendDao
11. ✅ 任务 11 — DriftLocalStore
12. ✅ 任务 12 — SyncEngine（含回调机制）
13. ✅ 任务 13 — barrel file
14. ✅ 任务 14 — Repository 改造（ConversationRepository）
15. ✅ 任务 15 — Repository 改造（MessageRepository）+ 自发消息 ACK 缓存写入
16. ✅ 任务 16 — Repository 改造（FriendRepository）
17. ✅ 任务 17 — main.dart 初始化流程 + home_page 回调注册
18. ✅ 任务 18 — 上层模块 pubspec 依赖更新 + sqlite3 hooks 配置
19. ✅ 任务 19 — flutter analyze 验证
