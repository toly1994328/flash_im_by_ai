# IM 协议 — 服务端任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。
本版本只做协议定义和代码生成，不写任何业务逻辑。

---

## 执行顺序

1. ✅ 任务 1 — 创建 proto/ws.proto（无依赖）
2. ✅ 任务 2 — 创建 im-ws crate 骨架（依赖任务 1）
   - ✅ 2.1 Cargo.toml
   - ✅ 2.2 build.rs
   - ✅ 2.3 src/proto.rs
   - ✅ 2.4 src/lib.rs
3. ✅ 任务 3 — 注册 workspace member（依赖任务 2）
4. ✅ 任务 4 — 创建统一协议生成脚本（依赖任务 1、2）
5. ✅ 任务 5 — 编译验证

---

## 任务 1：proto/ws.proto — 协议定义 `⬜`

文件：`proto/ws.proto`（新建）

### 1.1 创建文件 `⬜`

在项目根目录创建 `proto/ws.proto`，内容如下：

```protobuf
syntax = "proto3";
package im;

enum WsFrameType {
  PING = 0;
  PONG = 1;
  AUTH = 2;
  AUTH_RESULT = 3;
}

message WsFrame {
  WsFrameType type = 1;
  bytes payload = 2;
}

message AuthRequest {
  string token = 1;
}

message AuthResult {
  bool success = 1;
  string message = 2;
}
```

---

## 任务 2：server/modules/im-ws — crate 骨架 `⬜`

### 2.1 Cargo.toml `⬜`

文件：`server/modules/im-ws/Cargo.toml`（新建）

```toml
[package]
name = "im-ws"
version = "0.1.0"
edition = "2024"

[dependencies]
prost = "0.13"

[build-dependencies]
prost-build = "0.13"
```

### 2.2 build.rs `⬜`

文件：`server/modules/im-ws/build.rs`（新建）

```rust
fn main() {
    prost_build::compile_protos(
        &["../../proto/ws.proto"],
        &["../../proto/"],
    ).expect("Failed to compile proto files");
}
```

说明：
- 路径相对于 im-ws crate 根目录，`../../proto/` 指向项目根目录的 proto 文件夹
- prost-build 会将生成的代码输出到 `OUT_DIR`

### 2.3 src/proto.rs `⬜`

文件：`server/modules/im-ws/src/proto.rs`（新建）

```rust
//! Protobuf 生成代码

include!(concat!(env!("OUT_DIR"), "/im.rs"));
```

### 2.4 src/lib.rs `⬜`

文件：`server/modules/im-ws/src/lib.rs`（新建）

```rust
//! IM WebSocket 模块
//!
//! 当前版本仅包含 Protobuf 协议定义。
//! 连接管理、帧分发等业务逻辑在后续版本实现。

pub mod proto;
```

---

## 任务 3：server/Cargo.toml — 注册 workspace member `⬜`

文件：`server/Cargo.toml`（修改）

### 3.1 新增 workspace member `⬜`

在 `[workspace]` 的 members 列表中新增 `"modules/im-ws"`：

```toml
members = [
    ".",
    "modules/flash-core",
    "modules/flash-auth",
    "modules/flash-user",
    "modules/im-ws",
]
```

注意：im-ws 暂时不需要被主应用依赖（不加到 `[dependencies]` 中），只需要能独立编译即可。

---

## 任务 4：scripts/proto/gen.ps1 — 统一协议生成脚本 `⬜`

文件：`scripts/proto/gen.ps1`（新建）

### 4.1 创建脚本 `⬜`

一个脚本同时更新前后端的协议代码：

```powershell
# Protobuf 统一代码生成脚本
# 用法：powershell -ExecutionPolicy Bypass -File scripts/proto/gen.ps1
# 修改 proto/ 下的 .proto 文件后，执行此脚本即可同步更新前后端代码

$ErrorActionPreference = "Stop"

$protoDir = "proto"
$dartOut = "client/modules/flash_im_core/lib/src/data/proto"

# ===== 后端（Rust）=====
# prost-build 在 cargo build 时自动触发，这里显式编译 im-ws 确保生成
Write-Host "🔧 [后端] 编译 im-ws（触发 prost-build）..."
Push-Location server
cargo build -p im-ws
Pop-Location
Write-Host "✅ [后端] Rust proto 代码已生成"

# ===== 前端（Dart）=====
Write-Host "🔧 [前端] 生成 Dart proto 代码..."
New-Item -ItemType Directory -Force -Path $dartOut | Out-Null
protoc --proto_path=$protoDir --dart_out=$dartOut "$protoDir/ws.proto"
Write-Host "✅ [前端] Dart proto 代码已生成到 $dartOut"

Write-Host ""
Write-Host "🎉 前后端协议代码已同步更新"
```

后续新增 .proto 文件时，只需在脚本中追加对应的 protoc 命令行。

---

## 任务 5：编译验证 `⬜`

### 5.1 验证 im-ws crate 编译 `⬜`

在 `server/` 目录下执行：

```powershell
cargo build -p im-ws
```

预期结果：
- build.rs 成功编译 proto/ws.proto
- 生成的 Rust 代码包含 WsFrameType、WsFrame、AuthRequest、AuthResult
- 编译无错误

### 5.2 验证 workspace 整体编译 `⬜`

```powershell
cargo build
```

预期结果：整个 workspace 编译通过，im-ws 不影响其他 crate。

### 5.3 验证统一脚本 `⬜`

在项目根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/proto/gen.ps1
```

预期结果：后端编译成功 + 前端 Dart 代码生成成功，一条命令搞定。
