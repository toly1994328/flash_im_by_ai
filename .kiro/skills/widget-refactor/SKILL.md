---
name: widget-refactor
description: Flutter Widget/Page 组件重构执行技能。在需要对组件执行拆分、提取、简化时激活，确保按正确手法重构并验证通过。
metadata:
  model: manual
  last_modified: Sun, 14 Jun 2026 00:00:00 GMT

---

# Widget 组件重构

## 适用场景

- 评审已完成（问题清单已有），进入动手修改阶段
- 用户直接说"拆分这个文件"、"把 XX 提出去"
- 体检方案中的执行步骤

## 不适用

- 还没看过代码就要重构 → 先用 `widget-code-review` 评审

---

## 重构手法

### 提取手法

| 手法 | 时机 | 产出 |
|------|------|------|
| 提取独立 Widget 文件 | 30+ 行可独立构建的 UI 片段 | `xxx_widget.dart` |
| 提取 Scope Widget | 有独立数据订阅（`context.select`）的 UI 区域 | `xxx_scope.dart` |
| 提取 Handler | 事件处理逻辑超过 3 行，且不操作 State | `handler/xxx_handler.dart` |
| 提取 Cubit | View 层持有的业务状态 + WS/Stream 监听 | `logic/xxx_cubit.dart` |
| 提取值对象 | 3+ 个总是一起传递的参数 | `xxx_config.dart` 或同文件 class |
| 提取 Extension | 重复出现的转换/判断逻辑 | `data/xxx_ext.dart` |

### 简化手法

| 手法 | 时机 | 效果 |
|------|------|------|
| 事件总线替代 try-catch 包裹 | View 层每个调用都套 try-catch toast | 删除包裹函数，Cubit 内 emit 事件 |
| getter 替代重复条件 | 同一条件在 3+ 处出现 | 一处定义，多处 `_isXxx` |
| 方法引用替代内联闭包 | 回调逻辑 > 1 行 | `onTap: _doSomething` |
| 删除纯委托方法 | 方法只调用另一个方法 | 直接传目标方法引用 |
| WS 监听改命名方法 | listen 中的匿名闭包 | `.listen(_onXxx)` |
| Cubit getter 暴露派生值 | 外部每次从 state 手动判断 | `cubit.notice`、`cubit.pinnedMessages` |

### 目录组织手法

| 手法 | 时机 |
|------|------|
| 按功能建子文件夹 | 同一功能域 2+ 个文件（如 pinned/、notice/、menu/） |
| 页面骨架放 `index/` | 使 view 根目录全是文件夹，无散落文件 |
| 相关组件就近放 | 强相关组件放同一目录（如 skeleton、empty 放 index/） |

---

## 执行流程

1. **确认目标**：明确要解决的问题（来自评审清单或用户指令）
2. **创建新文件**：先把提取的代码写到新文件中（独立编译通过）
3. **更新引用**：原文件 import 新文件，替换内联代码为一行调用
4. **删除残留**：移除不再需要的 import、方法、字段
5. **编译验证**：`dart analyze lib` 零错误
6. **逐步推进**：一次只做一个手法，验证通过再做下一个
7. **输出总结**：重构完成后输出到 `docs/project/checkup/{版本}/client/{序号}_{文件名}_refactor_summary.md`

---

## 值对象设计原则

- 按**语义边界**分组，不是按"参数多"就塞一起
- 好的分组：`ChatTarget`（跟谁聊） vs `ChatViewOptions`（怎么显示）
- 坏的分组：一个 `ChatPageConfig` 混装身份+UI+状态+回调
- 回调不放值对象——回调是行为不是数据
- 命名简短有力：`ChatTarget`、`ChatViewOptions`，不要 `ChatPageConfigurationOptions`

---

## Scope Widget 设计原则

- 内部用 `context.select` 精确订阅，只在相关数据变化时重建
- 省略泛型，用参数类型标注：`context.select((ChatGroupCubit c) => c.notice)`
- 独立文件，const 构造
- 对外零参数或仅接收回调

---

## Handler 设计原则

- Handler 持有 Cubit 引用，处理 UI 事件的业务逻辑
- 不直接 emit State（与 Cubit mixin 的区别）
- 可持有多个依赖（cubit、media handler、repository getter）
- 方法签名接收 `BuildContext`（需要导航时）和业务参数

---

## 类注释规范

重构完成后，给主类加文档注释（参考 Flutter 源码风格）：

```dart
/// 聊天主页面。
///
/// 负责组装聊天相关的各个 UI 区域，自身不持有业务状态。
///
/// ## 页面结构
///
/// ```
/// ┌─────────────────────────────┐
/// │  ChatAppBar                 │
/// ├─────────────────────────────┤
/// │  NoticeBanner (群聊)        │
/// ├─────────────────────────────┤
/// │  MessageList                │
/// ├─────────────────────────────┤
/// │  InputSection / DisbandBar  │
/// └─────────────────────────────┘
/// ```
///
/// ## 状态来源
///
/// - [ChatCubit] — 消息列表、发送、多选
/// - [ChatGroupCubit] — 群组信息（仅群聊）
/// - [PeerStatusCubit] — 对端在线状态（仅单聊）
///
/// ## 事件委托
///
/// - [ChatMediaHandler] — 媒体打开与下载
/// - [ChatMenuHandler] — 菜单事件分发
class ChatPage extends StatefulWidget {
```

---

## 注意事项

- 一次只做一件事，做完验证再继续
- 不改变外部行为——重构是内部结构调整
- 新文件先编译通过再接入主文件
- 移动文件后立即修复所有 import（用 `dart analyze` 验证）
- barrel 文件（如 `flash_im_chat.dart`）同步更新 export 路径
- `context.select` 只能在 Widget 的 `build` 方法中直接调用，不能在 BlocBuilder 的 builder 回调中嵌套使用——后者用 `context.read` 取快照
- PowerShell `Set-Content` 会破坏 UTF-8 中文编码，文件写入必须用 `fs_write` 工具或 `[System.IO.File]::WriteAllText` + UTF8 编码
- 强类型数据类优于 `Map<String, dynamic>` — 加载时一次性解析，消除后续所有 `as String?`
- 每个操作的 try-catch + SnackBar 重复模式用 `ShowToastEvent` 事件总线替代，操作方法只需 emit 不需 catch
