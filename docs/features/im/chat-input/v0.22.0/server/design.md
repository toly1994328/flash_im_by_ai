---
module: im-chat-input
version: v0.22.0
date: 2026-05-17
tags: [语音消息, proto]
---

# 聊天输入框优化 — 服务端设计报告

## 1. 目标

- 支持语音消息类型（msg_type=4）的存储和广播
- 音频文件上传复用现有 app-storage 的文件上传逻辑

## 2. 现状分析

- app-storage 已支持文件上传（POST /api/upload/file），返回 file_url
- im-message 已支持 msg_type 0-3 和 5，type=4 未定义
- protobuf 的 MessageType 枚举需要新增 AUDIO=4
- 消息广播逻辑不需要改动（content 存 URL，extra 存时长，和文件消息一致）

## 3. 数据模型与接口

### 改动点

1. **proto 枚举**：`message.proto` 中 MessageType 新增 `AUDIO = 4`
2. **消息预览**：`generate_preview` 函数新增 `4 => "[语音]"`
3. **上传接口**：无需新增，复用 `/api/upload/file`

### 接口

音频上传走现有接口：

```
POST /api/upload/file
Content-Type: multipart/form-data
Field: file (audio.wav)

Response: { "file_url": "...", "file_name": "...", "file_size": ..., "file_type": "wav" }
```

## 4. 验收标准

| 验收条件 | 验收方式 |
|----------|----------|
| proto 编译通过 | `cargo build` |
| type=4 消息可正常存储和广播 | 前端发送语音，对方收到 |
| 会话预览显示"[语音]" | 发送语音后查看会话列表 |

## 5. 暂不实现

| 功能 | 理由 |
|------|------|
| 服务端音频转码 | 客户端录制 WAV 直接存储，不做转码 |
| 语音时长服务端校验 | 信任客户端传的 duration_ms |
