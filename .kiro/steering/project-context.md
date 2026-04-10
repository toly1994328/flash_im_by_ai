---
inclusion: always
---

# 项目全局上下文

## 后端服务

- 后端位于 `server/`，Rust workspace 模式
- 启动/重启后端服务：`python scripts/server/start.py`
- 该脚本会自动：检查并启动 PostgreSQL → 停止旧进程 → cargo build → cargo run
- 后端默认端口：9600，配置在 `server/.env`
- Protobuf 编译器路径已在 `server/modules/im-ws/build.rs` 中硬编码（`C:\toly\SDK\protoc\bin\protoc.exe`），`cargo build` 无需额外设置 PROTOC 环境变量
- 数据库重置：`python scripts/server/reset_db.py`

## 前端

- 前端位于 `client/`，Flutter 项目
- 模块化 packages 在 `client/modules/` 下（如 flash_auth）
- `client/lib/playground/` 是早期原型验证代码，已废弃，不要引用或修改
- 启动客户端（默认 Android）：`python scripts/client/run.py`
- 启动客户端（Windows 桌面）：`python scripts/client/run.py --platform windows`
- Android 模式下如果没有设备，会自动尝试 adb connect 127.0.0.1:7555 连接模拟器

## 语言

- 用户使用中文，文档和回复请用中文
