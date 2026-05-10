# 消息转发与@提及与置�?�?服务端任务清�?

基于 [design.md](design.md) 设计。改动集中在 im-message 模块，新�?pinned_messages 表和 4 个接口�?

---

## 执行顺序

### 阶段一：协议与数据�?

1. �?任务 1 �?proto 扩展（PIN_CHANGED + FORWARD 类型�?
2. �?任务 2 �?pinned_messages 表迁�?
3. �?任务 3 �?ConversationUpdate proto 扩展（last_message_extra�?

### 阶段二：转发接口

4. �?任务 4 �?转发接口（单�?+ 合并�?
5. �?任务 5 �?转发广播（CHAT_MESSAGE + ConversationUpdate�?

### 阶段三：置顶接口

6. �?任务 6 �?置顶接口（POST /pin�?
7. �?任务 7 �?取消置顶接口（DELETE /pin/{id}�?
8. �?任务 8 �?查询置顶列表（GET /pinned�?
9. �?任务 9 �?PIN_CHANGED 广播

### 阶段四：@提及支持

10. �?任务 10 �?ConversationUpdate 携带 last_message_extra

---

## 任务 1：proto 扩展 `⬜`

文件：`proto/ws.proto`、`proto/message.proto`（修改）

### 1.1 ws.proto 新增 PIN_CHANGED `⬜`

```protobuf
enum WsFrameType {
  // ... 已有 0~16
  PIN_CHANGED = 17;
}
```

### 1.2 message.proto 新增 FORWARD 类型 `⬜`

```protobuf
enum MessageType {
  // ... 已有 0~4
  FORWARD = 5;
}
```

### 1.3 message.proto 新增 PinChangedNotification `⬜`

```protobuf
message PinChangedNotification {
  string conversation_id = 1;
  string message_id = 2;
  string action = 3;       // "pin" �?"unpin"
  string pinned_by = 4;
}
```

### 1.4 编译验证 `⬜`

```bash
cargo build
```

---

## 任务 2：pinned_messages 表迁�?`⬜`

文件：`server/migrations/` 新建迁移文件

### 2.1 创建�?`⬜`

```sql
CREATE TABLE pinned_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id),
    message_id UUID NOT NULL REFERENCES messages(id),
    pinned_by BIGINT NOT NULL,
    pinned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(conversation_id, message_id)
);

CREATE INDEX idx_pinned_messages_conv ON pinned_messages(conversation_id);
```

### 2.2 运行迁移 `⬜`

```bash
sqlx migrate run
```

---

## 任务 3：ConversationUpdate proto 扩展 `⬜`

文件：`proto/ws.proto`（修改）

### 3.1 新增 last_message_extra 字段 `⬜`

```protobuf
message ConversationUpdate {
  // ... 已有字段 1~5
  string last_message_extra = 6;  // JSON 字符串，�?mentions �?
}
```

---

## 任务 4：转发接�?`⬜`

文件：`server/modules/im-message/src/routes.rs`、`service.rs`、`repository.rs`（修改）

### 4.1 路由注册 `⬜`

```rust
// ---> routes.rs
.route("/conversations/:conv_id/messages/forward", post(forward_message))
```

### 4.2 Handler 实现 `⬜`

```rust
// ---> routes.rs
async fn forward_message(
    State(state): State<AppState>,
    Path(conv_id): Path<String>,
    claims: Claims,
    Json(body): Json<ForwardRequest>,
) -> Result<Json<Value>, AppError> {
    // 1. 校验 message_ids 都属�?conv_id（安全校验）
    // 2. 校验用户是目标会话成�?
    // 3. 查询源消息列�?
    // 4. 根据 forward_type 处理�?
    //    - single: 逐条复制到目标会�?
    //    - merge: 构建 FORWARD 类型消息（type=5, extra=原始消息JSON�?
    // 5. 分配 seq + 存入 messages
    // 6. 广播 CHAT_MESSAGE + ConversationUpdate
    // 7. 返回 message_id + seq
}
```

### 4.3 ForwardRequest 模型 `⬜`

```rust
// ---> models.rs
#[derive(Deserialize)]
pub struct ForwardRequest {
    pub message_ids: Vec<String>,
    pub target_conversation_id: String,
    pub forward_type: String,  // "single" | "merge"
}
```

### 4.4 Service �?forward_message `⬜`

```rust
// ---> service.rs
pub async fn forward_message(
    &self,
    source_conv_id: &str,
    message_ids: &[String],
    target_conv_id: &str,
    forward_type: &str,
    user_id: i64,
    sender_name: &str,
) -> Result<(String, i64)>
// 返回 (new_message_id, seq)
```

单条转发：复�?content + type + extra，sender_id 改为转发者�?
合并转发：type=5，content="XXX的聊天记�?，extra=原始消息列表 JSON（最�?20 条）�?

---

## 任务 5：转发广�?`⬜`

文件：`server/modules/im-message/src/broadcast.rs`（修改）

### 5.1 转发后广�?CHAT_MESSAGE `⬜`

复用已有�?`broadcast_message` 方法，向目标会话所有成员广播新消息�?

### 5.2 转发后广�?ConversationUpdate `⬜`

更新目标会话�?last_message_preview + last_message_at，广�?ConversationUpdate 帧�?

---

## 任务 6：置顶接�?`⬜`

文件：`server/modules/im-message/src/routes.rs`、`service.rs`、`repository.rs`（修改）

### 6.1 路由注册 `⬜`

```rust
.route("/conversations/:conv_id/messages/pin", post(pin_message))
```

### 6.2 Handler 实现 `⬜`

```rust
async fn pin_message(
    State(state): State<AppState>,
    Path(conv_id): Path<String>,
    claims: Claims,
    Json(body): Json<PinRequest>,
) -> Result<Json<Value>, AppError> {
    // 1. 校验权限（群�?管理员）
    // 2. 校验消息存在
    // 3. 校验未超�?3 条上�?
    // 4. 校验未重复置�?
    // 5. 写入 pinned_messages
    // 6. 广播 PIN_CHANGED（action=pin�?
    // 7. 返回 pin_id + pinned_at
}
```

### 6.3 Repository �?`⬜`

```rust
// ---> repository.rs
pub async fn insert_pin(&self, conv_id: &str, msg_id: &str, pinned_by: i64) -> Result<PinnedMessage>
pub async fn count_pins(&self, conv_id: &str) -> Result<i64>
pub async fn is_pinned(&self, conv_id: &str, msg_id: &str) -> Result<bool>
```

---

## 任务 7：取消置顶接�?`⬜`

文件：`server/modules/im-message/src/routes.rs`、`repository.rs`（修改）

### 7.1 路由注册 `⬜`

```rust
.route("/conversations/:conv_id/messages/pin/:pin_id", delete(unpin_message))
```

### 7.2 Handler 实现 `⬜`

```rust
async fn unpin_message(
    State(state): State<AppState>,
    Path((conv_id, pin_id)): Path<(String, String)>,
    claims: Claims,
) -> Result<Json<Value>, AppError> {
    // 1. 校验权限（群�?管理员）
    // 2. 校验 pin_id 存在且属于该会话
    // 3. 删除 pinned_messages 记录
    // 4. 广播 PIN_CHANGED（action=unpin�?
    // 5. 返回 200
}
```

### 7.3 Repository �?`⬜`

```rust
pub async fn delete_pin(&self, pin_id: &str, conv_id: &str) -> Result<()>
pub async fn find_pin_by_id(&self, pin_id: &str) -> Result<Option<PinnedMessage>>
```

---

## 任务 8：查询置顶列�?`⬜`

文件：`server/modules/im-message/src/routes.rs`、`repository.rs`（修改）

### 8.1 路由注册 `⬜`

```rust
.route("/conversations/:conv_id/messages/pinned", get(get_pinned_messages))
```

### 8.2 Handler 实现 `⬜`

```rust
async fn get_pinned_messages(
    State(state): State<AppState>,
    Path(conv_id): Path<String>,
    claims: Claims,
) -> Result<Json<Vec<PinnedMessageWithContent>>, AppError> {
    // JOIN messages 表获取消息内�?
    // �?pinned_at DESC 排序
}
```

### 8.3 Repository �?`⬜`

```rust
pub async fn get_pinned_with_content(&self, conv_id: &str) -> Result<Vec<PinnedMessageWithContent>>
```

```sql
SELECT p.id as pin_id, p.message_id, m.content, m.type as msg_type,
       COALESCE(up.nickname, '?') as sender_name,
       p.pinned_by, p.pinned_at
FROM pinned_messages p
JOIN messages m ON p.message_id = m.id
LEFT JOIN user_profiles up ON m.sender_id = up.account_id
WHERE p.conversation_id = $1
ORDER BY p.pinned_at DESC
```

---

## 任务 9：PIN_CHANGED 广播 `⬜`

文件：`server/modules/im-message/src/broadcast.rs`（修改）

### 9.1 broadcast_pin_changed `⬜`

```rust
pub async fn broadcast_pin_changed(
    ws_state: &WsState,
    conv_repo: &ConversationRepository,
    conv_id: &str,
    message_id: &str,
    action: &str,  // "pin" | "unpin"
    pinned_by: i64,
) -> Result<()> {
    let payload = PinChangedNotification { conversation_id, message_id, action, pinned_by };
    let frame = WsFrame::new(WsFrameType::PinChanged, payload.encode_to_vec());
    let member_ids = conv_repo.get_member_ids(conv_id).await?;
    for uid in member_ids {
        ws_state.send(uid, frame.clone());
    }
    Ok(())
}
```

---

## 任务 10：ConversationUpdate 携带 last_message_extra `⬜`

文件：`server/modules/im-message/src/broadcast.rs`（修改）

### 10.1 广播 ConversationUpdate 时填�?last_message_extra `⬜`

当消息的 extra 包含 mentions 时，�?extra JSON 字符串填�?ConversationUpdate �?`last_message_extra` 字段。会话列表据此判断是否显�?有人@�?�?

```rust
// broadcast_conversation_update 改�?
let update = ConversationUpdate {
    conversation_id: conv_id.to_string(),
    last_message_preview: preview,
    last_message_at: timestamp,
    last_message_extra: msg_extra.unwrap_or_default(),  // 新增
};
```
