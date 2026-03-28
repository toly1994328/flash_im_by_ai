# im-ws

IM WebSocket 模块，使用 Protobuf 二进制协议通信。

## 依赖

本模块的 `build.rs` 会在编译时调用 `prost-build` 从 `proto/ws.proto` 生成 Rust 代码。

需要安装 `protoc` 编译器：
- Windows：运行 `powershell -ExecutionPolicy Bypass -File scripts/proto/gen.ps1`，首次执行会自动下载安装到 `C:\toly\SDK\protoc\`
- 其他平台：从 https://github.com/protocolbuffers/protobuf/releases 下载，确保 `protoc` 在 PATH 中

如果 `protoc` 不在默认 PATH 中，`build.rs` 会尝试从 `C:\toly\SDK\protoc\bin\protoc.exe` 查找。其他环境可通过设置 `PROTOC` 环境变量指定路径。

## 生成代码

- 生成的 Rust 代码位于 `src/generated/im.rs`，由 `src/proto.rs` 通过 `include!` 引入
- 生成的代码已提交到 Git，正常情况下 `cargo build` 即可编译
- 修改 `proto/ws.proto` 后需要重新编译触发生成

## 模块结构

```
src/
├── lib.rs           # 模块入口
├── proto.rs         # Protobuf 生成代码入口
├── generated/
│   └── im.rs        # prost-build 生成（不要手动编辑）
├── handler.rs       # WebSocket 连接处理（认证、消息循环）
└── dispatcher.rs    # 帧分发（按 type 路由）
```
