# 消息置顶 — 服务端任务清单

基于 [design.md](design.md) 设计。改动集中在 im-message 模块，新建 pinned_messages 表和 3 个接口。

---

## 执行顺序

### 阶段一：协议与数据层

1. ✅ 任务 1 — proto 扩展（PIN_CHANGED + PinChangedNotification）
2. ✅ 任务 2 — pinned_messages 表迁移

### 阶段二：置顶接口

3. ✅ 任务 3 — 置顶接口（POST /pin）
4. ✅ 任务 4 — 取消置顶接口（DELETE /pin/{id}）
5. ✅ 任务 5 — 查询置顶列表（GET /pinned）
6. ✅ 任务 6 — PIN_CHANGED 广播

---

## 任务 1：proto 扩展 `✅`

文件：`proto/ws.proto`（修改）

### 1.1 新增 PIN_CHANGED 帧类型 `✅`

```protobuf
enum WsFrameType {
  // ... 已有 0~16
  PIN_CHANGED = 17;
}
```

### 1.2 新增 PinChangedNotification `✅`

```protobuf
message PinChangedNotification {
  string conversation_id = 1;
  string message_id = 2;
  string action = 3;       // "pin" 或 "unpin"
  string pinned_by = 4;
}
```

---

## 任务 2：pinned_messages 表迁移 `✅`

文件：`server/migrations/20260508_008_pinned_messages.sql`（新建）

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

---

## 任务 3：置顶接口 `✅`

文件：`server/modules/im-message/src/routes.rs`、`service.rs`、`repository.rs`（修改）

### 3.1 路由注册 `✅`

```rust
.route("/conversations/:conv_id/messages/pin", post(pin_message))
```

### 3.2 Handler 实现 `✅`

```rust
async fn pin_message(...) -> Result<Json<Value>, AppError> {
    // 1. 校验用户是会话成员
    // 2. 校验消息存在
    // 3. 校验未超过 3 条上限
    // 4. 校验未重复置顶
    // 5. 写入 pinned_messages
    // 6. 广播 PIN_CHANGED（action=pin）
    // 7. 返回 pin_id + pinned_at
}
```

### 3.3 Repository 层 `✅`

```rust
pub async fn insert_pin(&self, conv_id: &str, msg_id: &str, pinned_by: i64) -> Result<PinnedMessage>
pub async fn count_pins(&self, conv_id: &str) -> Result<i64>
pub async fn is_pinned(&self, conv_id: &str, msg_id: &str) -> Result<bool>
```

---

## 任务 4：取消置顶接口 `✅`

文件：`server/modules/im-message/src/routes.rs`、`repository.rs`（修改）

### 4.1 路由注册 `✅`

```rust
.route("/conversations/:conv_id/messages/pin/:pin_id", delete(unpin_message))
```

### 4.2 Handler 实现 `✅`

```rust
async fn unpin_message(...) -> Result<Json<Value>, AppError> {
    // 1. 校验用户是会话成员
    // 2. 校验 pin_id 存在且属于该会话
    // 3. 删除 pinned_messages 记录
    // 4. 广播 PIN_CHANGED（action=unpin）
    // 5. 返回 200
}
```

### 4.3 Repository 层 `✅`

```rust
pub async fn delete_pin(&self, pin_id: &str, conv_id: &str) -> Result<()>
pub async fn find_pin_by_id(&self, pin_id: &str) -> Result<Option<PinnedMessage>>
```

---

## 任务 5：查询置顶列表 `✅`

文件：`server/modules/im-message/src/routes.rs`、`repository.rs`（修改）

### 5.1 路由注册 `✅`

```rust
.route("/conversations/:conv_id/messages/pinned", get(get_pinned_messages))
```

### 5.2 Handler + Repository `✅`

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

## 任务 6：PIN_CHANGED 广播 `✅`

文件：`server/modules/im-message/src/broadcast.rs`（修改）

### 6.1 broadcast_pin_changed `✅`

```rust
pub async fn broadcast_pin_changed(
    ws_state: &WsState,
    conv_repo: &ConversationRepository,
    conv_id: &str,
    message_id: &str,
    action: &str,
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
