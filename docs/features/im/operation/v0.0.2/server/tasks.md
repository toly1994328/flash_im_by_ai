# 消息转发 — 服务端任务清单

基于 [design.md](design.md) 设计。改动集中在 im-message 模块。

---

## 执行顺序

### 阶段一：协议

1. ✅ 任务 1 — proto 扩展（FORWARD 类型）

### 阶段二：转发接口

2. ✅ 任务 2 — 转发接口（单条）
3. ✅ 任务 3 — 转发广播（send_include_self）

---

## 任务 1：proto 扩展 `✅`

文件：`proto/message.proto`（修改）

### 1.1 新增 FORWARD 类型 `✅`

```protobuf
enum MessageType {
  // ... 已有 0~4
  FORWARD = 5;
}
```

---

## 任务 2：转发接口 `✅`

文件：`server/modules/im-message/src/routes.rs`、`service.rs`（修改）

### 2.1 路由注册 `✅`

```rust
.route("/conversations/:conv_id/messages/forward", post(forward_message))
```

### 2.2 Handler 实现 `✅`

```rust
async fn forward_message(
    State(state): State<AppState>,
    Path(conv_id): Path<String>,
    claims: Claims,
    Json(body): Json<ForwardRequest>,
) -> Result<Json<Value>, AppError> {
    // 1. 校验 message_ids 都属于 conv_id
    // 2. 校验用户是目标会话成员
    // 3. 查询源消息
    // 4. 复制消息内容到目标会话
    // 5. 分配 seq + 存入 messages
    // 6. 广播 CHAT_MESSAGE + ConversationUpdate（send_include_self）
    // 7. 返回 message_id + seq
}
```

### 2.3 ForwardRequest 模型 `✅`

```rust
#[derive(Deserialize)]
pub struct ForwardRequest {
    pub message_ids: Vec<String>,
    pub target_conversation_id: String,
    pub forward_type: String,  // "single"
}
```

---

## 任务 3：转发广播 `✅`

文件：`server/modules/im-message/src/broadcast.rs`（修改）

### 3.1 send_include_self 广播 `✅`

转发后使用 `send_include_self` 向目标会话所有成员（含转发者）广播 CHAT_MESSAGE + ConversationUpdate。
