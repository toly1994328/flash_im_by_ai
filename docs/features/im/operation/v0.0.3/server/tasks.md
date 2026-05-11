# @提及 — 服务端任务清单

基于 [design.md](design.md) 设计。改动极少，主要是 proto 扩展和广播逻辑。

---

## 执行顺序

1. ✅ 任务 1 — ConversationUpdate proto 扩展（last_message_extra）
2. ✅ 任务 2 — 广播 ConversationUpdate 时填充 last_message_extra

---

## 任务 1：ConversationUpdate proto 扩展 `✅`

文件：`proto/ws.proto`（修改）

### 1.1 新增 last_message_extra 字段 `✅`

```protobuf
message ConversationUpdate {
  // ... 已有字段 1~5
  string last_message_extra = 6;  // JSON 字符串，含 mentions 等
}
```

---

## 任务 2：广播填充 last_message_extra `✅`

文件：`server/modules/im-message/src/broadcast.rs`（修改）

### 2.1 broadcast_conversation_update 改造 `✅`

当消息的 extra 包含 mentions 时，将 extra JSON 字符串填入 ConversationUpdate 的 `last_message_extra` 字段：

```rust
let update = ConversationUpdate {
    conversation_id: conv_id.to_string(),
    last_message_preview: preview,
    last_message_at: timestamp,
    last_message_extra: msg_extra.unwrap_or_default(),
};
```
