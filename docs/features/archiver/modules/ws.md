# WebSocket 通信域 — 局域网络

涉及节点：I-05~I-09, F-04~F-06

---

## 节点详情

| 编号 | 功能节点 | 模块 | 端 | 职责 |
|------|---------|------|-----|------|
| I-05 | WebSocket 连接管理 | im-ws | 后端 | 连接建立、关闭、handler 循环 |
| I-06 | 帧协议编解码 | im-ws | 后端 | WsFrame Protobuf 编解码 |
| I-07 | 心跳保活 | im-ws | 后端 | PING/PONG 帧处理 |
| I-08 | 在线用户管理 | im-ws (WsState) | 后端 | channel 管理在线连接，send_to_user |
| I-09 | 帧分发器 | im-ws (dispatcher) | 后端 | 按帧类型分发处理（CHAT_MESSAGE → service.send） |
| F-04 | WsClient 连接与认证 | flash_im_core | 前端 | WebSocket 连接、AUTH 帧握手 |
| F-05 | WsClient 心跳与重连 | flash_im_core | 前端 | PING 定时发送、断线指数退避重连 |
| F-06 | WsClient 帧分发 | flash_im_core | 前端 | 按帧类型分发到 chatMessageStream / messageAckStream / conversationUpdateStream |

---

## 边界接口

### Protobuf 协议

| 文件 | 结构 | 消费节点 |
|------|------|---------|
| ws.proto | WsFrame, WsFrameType | I-05, I-06, I-09, F-04, F-06 |
| ws.proto | AuthRequest, AuthResult | I-05, F-04 |

---

## 版本演进

| 版本 | 变更 |
|------|------|
| v0.0.1 | 初始：I-05~I-07, F-04~F-05 |
| v0.0.3 | 新增 I-08 在线用户管理、I-09 帧分发器、F-06 帧分发 |
