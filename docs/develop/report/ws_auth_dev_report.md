# WebSocket + JWT 认证整合 开发报告

> 模块名称：认证通信（ws_auth）  
> 日期：2026-03-15  
> 更新：增加聊天室广播 + 底部导航

---

## 一、需求背景

此前 Playground 中有两个独立模块：

| 模块 | 功能 | 缺陷 |
|------|------|------|
| 💓 心跳通信 | WebSocket 双向通信 | 匿名连接，无身份 |
| 🔐 用户认证 | HTTP 登录 + JWT | 仅 HTTP，未接入 WS |

在正式 IM 产品中，WebSocket 连接必须携带身份，且需要支持多人聊天。本次整合将两者打通，并实现聊天室广播。

---

## 二、技术方案

采用 **首消息认证（First-Message Auth）** 模式，参考 `flash_im-main` 参考项目的实现：

```mermaid
sequenceDiagram
    participant C as 客户端
    participant S as 服务端

    C->>S: WebSocket 握手请求
    S-->>C: 101 Switching Protocols
    Note over S: 启动 10s 认证计时器

    C->>S: {"token": "eyJhbG..."}
    S->>S: 验证 JWT 签名 & 过期时间
    S->>S: 提取 user_id，绑定连接

    alt 认证成功
        S-->>C: {"type":"auth_ok","user_id":1,"nickname":"..."}
        Note over C,S: 进入带身份的消息通信
    else Token 无效
        S-->>C: {"type":"auth_fail"}
        S->>C: 关闭连接
    else 10s 超时
        S-->>C: {"type":"auth_timeout"}
        S->>C: 关闭连接
    end
```

### 聊天室广播架构

```mermaid
flowchart TB
    subgraph 服务端
        TX[broadcast::Sender]
        RX1[Receiver 1]
        RX2[Receiver 2]
        RX3[Receiver N]
        TX --> RX1
        TX --> RX2
        TX --> RX3
    end

    subgraph 客户端
        C1[用户 A] -->|发送消息| TX
        C2[用户 B] -->|发送消息| TX
        RX1 -->|推送| C1
        RX2 -->|推送| C2
        RX3 -->|推送| C3[用户 N]
    end
```

使用 Tokio 的 `broadcast::channel` 实现多人消息广播。每个连接认证后订阅频道，发送的消息通过 `Sender` 广播给所有订阅者。

### 为什么不用 URL 参数传 Token？

`ws://host/ws?token=xxx` 会将 Token 暴露在服务器日志、代理日志中。首消息认证将 Token 放在 WebSocket 数据帧内，更安全。

---

## 三、实现清单

### 后端（Rust / Axum）

| 端点 | 功能 | 认证 |
|------|------|------|
| `/ws` | 基础 WebSocket（echo） | ❌ |
| `/ws/auth` | 认证 WebSocket（echo） | ✅ 首消息 JWT |
| `/ws/chat_room` | 聊天室广播 | ✅ 首消息 JWT |

`/ws/chat_room` 新增能力：
- `broadcast::channel` 多人消息广播
- `join` / `leave` 事件通知
- `socket.split()` 读写分离，独立 task 处理收发

消息协议：

```json
{"type":"auth_ok","user_id":1,"nickname":"13800138000"}
{"type":"message","user_id":1,"nickname":"13800138000","text":"hello"}
{"type":"join","user_id":1,"nickname":"13800138000"}
{"type":"leave","user_id":1,"nickname":"13800138000"}
```

### 前端（Flutter）

页面结构改为底部导航：

```mermaid
flowchart TB
    Login[登录页] -->|登录成功| Main[主界面]
    Main --> Tab1[💬 聊天室]
    Main --> Tab2[👤 我的]
    Tab1 -->|加入| WS["/ws/chat_room"]
    Tab2 -->|退出登录| Login
```

| 文件 | 说明 |
|------|------|
| `ws_auth/api/ws_auth_api.dart` | 通信层，支持 `/ws/auth` 和 `/ws/chat_room` |
| `ws_auth/view/ws_auth_page.dart` | 登录 + BottomNavigationBar（聊天室 / 我的） |

前端连接状态机：

```mermaid
stateDiagram-v2
    [*] --> disconnected
    disconnected --> connecting : 加入聊天室
    connecting --> authenticating : 握手成功
    authenticating --> authenticated : auth_ok
    authenticating --> disconnected : auth_fail / timeout
    authenticated --> disconnected : 离开 / 异常
```

---

## 四、目录结构

```
client/lib/playground/
├── ws_auth/
│   ├── api/
│   │   └── ws_auth_api.dart      # 支持 /ws/auth + /ws/chat_room
│   └── view/
│       └── ws_auth_page.dart     # 登录 → 底部导航（聊天室 + 我的）
└── playground_page.dart          # 入口 🔗 认证通信

server/src/
└── main.rs                       # /ws/auth + /ws/chat_room
```

---

## 五、测试验证

### 聊天室测试（多终端）

```bash
# 终端 1：用户 A 登录
curl -s -X POST http://localhost:9600/auth/sms -H "Content-Type: application/json" -d '{"phone":"13800000001"}'
curl -s -X POST http://localhost:9600/auth/login -H "Content-Type: application/json" -d '{"phone":"13800000001","code":"CODE_A"}'
# 拿到 TOKEN_A

# 终端 2：用户 B 登录
curl -s -X POST http://localhost:9600/auth/sms -H "Content-Type: application/json" -d '{"phone":"13800000002"}'
curl -s -X POST http://localhost:9600/auth/login -H "Content-Type: application/json" -d '{"phone":"13800000002","code":"CODE_B"}'
# 拿到 TOKEN_B

# 终端 1：用户 A 加入聊天室
wscat -c ws://localhost:9600/ws/chat_room
> {"token":"TOKEN_A"}
< {"type":"auth_ok",...}

# 终端 2：用户 B 加入聊天室
wscat -c ws://localhost:9600/ws/chat_room
> {"token":"TOKEN_B"}
< {"type":"auth_ok",...}
< {"type":"join",...}     # A 收到 B 加入通知

# 用户 A 发消息，B 也能收到
> hello
< {"type":"message","user_id":1,"nickname":"13800000001","text":"hello"}
```

### 前端操作流程

```mermaid
flowchart LR
    A[打开 认证通信] --> B[登录]
    B --> C[进入主界面]
    C --> D[聊天室 Tab]
    D --> E[加入聊天室]
    E --> F[多人收发消息]
    C --> G[我的 Tab]
    G --> H[查看信息 / 退出]
```

---

## 六、Playground 进度总览

| # | 模块 | 练习点 | 状态 |
|---|------|--------|------|
| 1 | 🎆 烟花秀 | Canvas & 粒子系统 | ✅ |
| 2 | 💬 会话列表 | HTTP 请求 & 列表渲染 | ✅ |
| 3 | 💓 心跳通信 | WebSocket 双向通信 | ✅ |
| 4 | 🔐 用户认证 | JWT 登录 & Token 鉴权 | ✅ |
| 5 | 🔗 认证通信 | WS+JWT 整合 + 聊天室广播 | ✅ |
