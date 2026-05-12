---
name: flutter-build-verify
description: Flutter 多模块项目的构建验证流程。在前端实现完成后激活，确保编译通过、代码生成正确。
metadata:
  model: manual
  last_modified: Mon, 12 May 2026 00:00:00 GMT

---
# Flutter 构建验证技能

## 适用场景

在 Flutter 前端代码实现完成后，执行构建验证流程，确保零编译错误。

## 验证流程

### 1. 代码生成（如涉及 drift 表定义变更）

如果本次改动涉及 drift 数据库表定义（`client/modules/flash_im_cache` 下的 tables/），必须先运行代码生成：

```bash
cd client/modules/flash_im_cache
dart run build_runner build --delete-conflicting-outputs
```

触发条件：
- 新增或修改了 `*_table.dart` 文件
- 修改了 drift 的 `@DriftDatabase` 注解中的 tables 列表
- 新增或修改了 DAO 文件

### 2. 全量编译分析（不可跳过）

```bash
cd client
flutter analyze
```

这是硬性门禁，必须零错误才能进入下一步。

### 3. 为什么不能用 getDiagnostics 替代

`getDiagnostics` 只检查单个文件的语法和类型，无法发现：
- 跨模块的类型不匹配（改了 core 包的类，chat 包的引用还是旧的）
- import 路径错误（文件移动后旧路径未更新）
- copyWith 参数缺失（新增字段后忘了更新 copyWith）
- 未使用的 import 或变量（analyze 会报 warning）

## 常见编译错误及原因

| 错误类型 | 典型原因 | 修复方式 |
|----------|---------|---------|
| 类型不匹配 | 改了模型字段但忘了更新 copyWith | 补全 copyWith 参数 |
| 方法未定义 | 改了接口签名但忘了更新调用方 | 全局搜索旧签名，逐一更新 |
| import 失败 | 文件移动或重命名后旧路径未更新 | 修正 import 路径 |
| 参数数量不匹配 | 构造函数新增 required 参数 | 所有调用处补上新参数 |
| drift 生成文件过期 | 改了表定义但没跑 build_runner | 重新运行代码生成 |

## 多模块项目注意事项

本项目是多模块结构（`client/modules/` 下多个 package），跨模块的类型变更是编译错误的重灾区：

- `flash_im_core`：基础类型和 WsClient，被所有模块依赖
- `flash_im_cache`：本地存储，被 conversation 和 chat 依赖
- `flash_im_conversation`：会话数据模型，被 chat 依赖
- `flash_im_chat`：聊天页面，依赖以上所有模块
- `flash_shared`：通用 UI 组件，被多个模块复用

改了底层模块的类（如 `Conversation` 新增字段），上层所有引用该类的模块都可能需要同步更新。`flutter analyze` 会一次性报出所有错误，逐一修复即可。

## 验证通过标准

```
Analyzing client...
No issues found!
```

看到这行输出，才能进入下一步。任何 error 都必须修复，info 和 warning 建议修复但不阻塞。
