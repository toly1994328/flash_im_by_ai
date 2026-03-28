# IM Core — 服务端任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。
复用 flash-core 的 verify_token 进行认证，不查数据库。
本版本不实现在线用户表、消息处理、上下线广播。

---

## 执行顺序

1. ⬜ 任务 1 — 扩展 im-ws 依赖（无依赖）
2. ⬜ 任务 2 — 实现 dispatcher.rs（依赖任务 1）
3. ⬜ 任务 3 — 实现 handler.rs（依赖任务 2）
4. ⬜ 任务 4 — 更新 lib.rs 导出（依赖任务 2、3）
5. ⬜ 任务 5 — 集成到 main.rs + 删除旧 ws 代码（依赖任务 4）
6. ⬜ 任务 6 — 编译验证

---

## 任务 1：im-ws/Cargo.toml — 扩展依赖 `⬜`

文件：`server/modules/im-ws/Cargo.toml`（修改）

### 1.1 添加 workspace 依赖 `⬜`

当前只有 prost 和 prost-build，需要新增：

```toml
[package]
name = "im-ws"
version = "0.1.0"
edition = "2024"

[dependencies]
flash-core = { path = "../flash-core" }
prost = "0.13"
axum.workspace = true
tokio.workspace = true
futures = "0.3"

[build-dependencies]
prost-build = "0.13"
```

说明：
- `flash-core`：复用 verify_token
- `axum`：WebSocket 支持（ws 特性已在 workspace 中配置）
- `tokio`：异步运行时、timeout
- `futures`：SinkExt/StreamExt 用于 WebSocket 读写分离

---

## 任务 2：dispatcher.rs — 帧分发器 `⬜`

文件：`server/modules/im-ws/src/dispatcher.rs`（新建）

### 2.1 帧分发函数 `⬜`

根据 WsFrameType 分发到对应处理逻辑。当前只处理 PING。

```rust
use axum::extract::ws::{Message, WebSocket};
use futures::SinkExt;
use prost::Message as ProstMessage;

use crate::proto::{WsFrame, WsFrameType};

/// 处理收到的帧，返回需要回复的帧（如果有）
pub async fn handle_frame(frame: WsFrame) -> Option<Vec<u8>> {
    // 1. 解析 frame.r#type 为 WsFrameType
    // 2. match frame_type:
    //    - Ping => 构建 PONG 帧，返回 Some(编码后的字节)
    //    - 其他 => 打印日志，返回 None
}
```

---

## 任务 3：handler.rs — 连接处理 `⬜`

文件：`server/modules/im-ws/src/handler.rs`（新建）

### 3.1 认证等待函数 `⬜`

等待客户端发送 AUTH 帧，10 秒超时。

```rust
use axum::extract::ws::{Message, WebSocket};
use futures::StreamExt;
use prost::Message as ProstMessage;

use crate::proto::{AuthRequest, WsFrame, WsFrameType};

/// 等待 AUTH 帧，解析 token，返回 user_id
/// 只接受 Binary 消息（Protobuf 帧）
async fn wait_for_auth(
    receiver: &mut futures::stream::SplitStream<WebSocket>,
) -> Option<i64> {
    // 1. 从 receiver 读取下一条 Binary 消息
    // 2. 解码为 WsFrame
    // 3. 检查 type == AUTH
    // 4. 解码 payload 为 AuthRequest
    // 5. 调用 flash_core::jwt::verify_token(&auth_req.token)
    // 6. 返回 Some(user_id) 或 None
}
```

### 3.2 WebSocket 升级处理函数 `⬜`

Axum 路由处理器，接受 WebSocket 升级。

```rust
use axum::{
    extract::ws::WebSocketUpgrade,
    response::IntoResponse,
};

/// GET /ws/im — WebSocket 升级端点
pub async fn ws_handler(ws: WebSocketUpgrade) -> impl IntoResponse {
    ws.on_upgrade(handle_socket)
}
```

### 3.3 连接主逻辑 `⬜`

管理单条连接的完整生命周期。

```rust
/// 处理单个 WebSocket 连接
async fn handle_socket(socket: WebSocket) {
    // 1. split socket 为 sender + receiver
    // 2. tokio::time::timeout(10s, wait_for_auth(&mut receiver))
    // 3. 认证失败/超时 → 发送 AUTH_RESULT(success=false)，关闭连接
    // 4. 认证成功 → 发送 AUTH_RESULT(success=true)
    // 5. 打印日志：用户 {user_id} 已连接
    // 6. 进入消息循环：
    //    while let Some(Ok(msg)) = receiver.next().await
    //      - Binary(data) → 解码 WsFrame → handle_frame → 如有回复则发送
    //      - Close(_) → break
    //      - 其他 → 忽略
    // 7. 打印日志：用户 {user_id} 已断开
}
```

---

## 任务 4：lib.rs — 更新模块导出 `⬜`

文件：`server/modules/im-ws/src/lib.rs`（修改）

### 4.1 新增模块声明 `⬜`

```rust
pub mod proto;
pub mod handler;
pub mod dispatcher;
```

导出 handler 中的 ws_handler 供 main.rs 使用。

---

## 任务 5：main.rs — 集成 + 清理旧代码 `⬜`

### 5.1 删除旧 ws 模块 `⬜`

删除整个 `server/src/ws/` 目录（auth.rs、chat_room.rs、handler.rs、mod.rs、routes.rs）。

删除 `server/src/main.rs` 中的 `mod ws;` 声明和 `ws::routes::router()` 合并。

### 5.2 清理 AppState `⬜`

文件：`server/modules/flash-core/src/state.rs`（修改）

移除 `chat_tx: broadcast::Sender<String>` 字段和 `create_app_state` 中的 broadcast::channel 创建。
移除 `User` 结构体（旧的 JSON 聊天室用的，新协议不需要）。
移除 `use tokio::sync::broadcast;`。

简化后的 AppState：

```rust
use sqlx::PgPool;
use std::sync::Arc;

pub struct AppState {
    pub db: PgPool,
}

pub fn create_app_state(db: PgPool) -> Arc<AppState> {
    Arc::new(AppState { db })
}
```

### 5.3 注册新路由 `⬜`

文件：`server/src/main.rs`（修改）

```rust
// 删除: mod ws;
// 删除: .merge(ws::routes::router())

// 新增:
use axum::routing::get;
use im_ws::handler::ws_handler;

// 在 Router 构建中新增:
.route("/ws/im", get(ws_handler))
```

### 5.4 添加 im-ws 到主应用依赖 `⬜`

文件：`server/Cargo.toml`（修改）

在 `[dependencies]` 中新增：

```toml
im-ws = { path = "modules/im-ws" }
```

---

## 任务 6：编译验证 `⬜`

### 6.1 编译 `⬜`

```powershell
cd server
cargo build
```

预期：整个 workspace 编译通过，无 error。旧的 ws 模块已删除，新的 im-ws handler 已注册。

### 6.2 启动验证 `⬜`

```powershell
powershell -ExecutionPolicy Bypass -File scripts/server/start.ps1
```

预期：服务正常启动，打印监听地址。`/ws/im` 端点可接受 WebSocket 连接。

### 6.3 功能验证路径 `⬜`

用 WebSocket 测试工具连接 `ws://127.0.0.1:9600/ws/im`：

1. 连接成功后，发送 AUTH 帧（Binary，Protobuf 编码的 WsFrame，type=AUTH，payload=AuthRequest{token}）
2. 收到 AUTH_RESULT 帧（success=true）
3. 发送 PING 帧，收到 PONG 帧
4. 不发送 AUTH 帧等待 10 秒，连接被服务端关闭
