# IM 协议 — 客户端任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。
本版本只做模块骨架和代码生成，不写任何业务逻辑。
模块遵循三层架构（data/logic/view），与 flash_auth、flash_session 保持一致。

---

## 执行顺序

1. ✅ 任务 1 — 创建 flash_im_core 模块骨架（无依赖）
   - ✅ 1.1 pubspec.yaml
   - ✅ 1.2 barrel 导出文件
   - ✅ 1.3 三层目录结构
2. ✅ 任务 2 — 生成 Protobuf Dart 代码（依赖任务 1 + proto/ws.proto + 统一脚本）
   - ✅ 2.1 安装工具
   - ✅ 2.2 执行统一生成脚本
3. ✅ 任务 3 — 注册模块依赖（依赖任务 2）
4. ✅ 任务 4 — 编译验证

---

## 任务 1：flash_im_core 模块骨架 `✅`

如果之前运行过 gen.ps1 导致 `client/modules/flash_im_core` 目录已存在但不是标准 package，先删除：

```powershell
Remove-Item -Recurse -Force client/modules/flash_im_core
```

然后使用 Flutter 命令行创建标准 package：

```powershell
cd client/modules
flutter create --template=package --project-name=flash_im_core flash_im_core
```

创建后再调整为三层架构并添加 protobuf 依赖。

### 1.1 创建标准 package `✅`

在 `client/modules/` 下执行上述命令，生成标准的 Flutter package 骨架。

### 1.2 添加 protobuf 依赖 `✅`

文件：`client/modules/flash_im_core/pubspec.yaml`（新建）

```yaml
name: flash_im_core
description: Flash IM 核心模块 — WebSocket 通信与协议
version: 0.0.1
publish_to: none

environment:
  sdk: ^3.7.0

dependencies:
  flutter:
    sdk: flutter
  protobuf: ^6.0.0
```

### 1.2 barrel 导出文件 `⬜`

文件：`client/modules/flash_im_core/lib/flash_im_core.dart`（新建）

```dart
/// Flash IM 核心模块
///
/// 当前版本仅包含 Protobuf 协议定义。
/// WebSocket 管理器等业务逻辑在后续版本实现。
library;

// data - proto
export 'src/data/proto/ws.pb.dart';
export 'src/data/proto/ws.pbenum.dart';
```

### 1.3 三层目录结构 `⬜`

创建以下目录（logic/ 和 view/ 本版本为空目录）：

```
client/modules/flash_im_core/lib/src/
├── data/
│   └── proto/          # protoc 生成代码放这里
├── logic/              # 空，下一版本放 WsClient
└── view/               # 空，预留
```

在 logic/ 和 view/ 下各放一个 `.gitkeep` 文件保持目录结构。

---

## 任务 2：生成 Protobuf Dart 代码 `⬜`

前提：`proto/ws.proto` 已由服务端任务创建。

### 2.1 安装工具 `⬜`

确保以下工具已安装：

```powershell
# protoc 编译器（如未安装，从 https://github.com/protocolbuffers/protobuf/releases 下载）
protoc --version

# protoc-gen-dart 插件
dart pub global activate protoc_plugin
```

### 2.2 执行统一生成脚本 `⬜`

统一脚本由服务端任务创建（`scripts/proto/gen.ps1`），在项目根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/proto/gen.ps1
```

该脚本会同时更新后端（cargo build -p im-ws）和前端（protoc → Dart）的协议代码。

预期生成文件：
- `client/modules/flash_im_core/lib/src/data/proto/ws.pb.dart`
- `client/modules/flash_im_core/lib/src/data/proto/ws.pbenum.dart`
- `client/modules/flash_im_core/lib/src/data/proto/ws.pbjson.dart`

---

## 任务 3：注册模块依赖 `⬜`

### 3.1 主工程 pubspec.yaml `⬜`

文件：`client/pubspec.yaml`（修改）

在 `dependencies` 中新增 flash_im_core 的路径依赖：

```yaml
  flash_im_core:
    path: modules/flash_im_core
```

注意：本版本只注册依赖，不在任何代码中 import 使用。

---

## 任务 4：编译验证 `⬜`

### 4.1 验证模块编译 `⬜`

在 `client/` 目录下执行：

```powershell
flutter pub get
```

预期结果：依赖解析成功，flash_im_core 被识别。

### 4.2 验证代码分析 `⬜`

```powershell
flutter analyze
```

预期结果：
- flash_im_core 模块无 error
- 生成的 proto 代码可能有 info 级别提示（如 unused import），不影响编译
- 项目整体无新增 error
