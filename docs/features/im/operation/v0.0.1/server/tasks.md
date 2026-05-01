# 消息操作 — 服务端任务清单

基于 [design.md](design.md) 设计。后端改动集中在消息撤回，引用回复不需要后端改动。

---

## 执行顺序

1. ✅ 任务 1 — proto 扩展（MESSAGE_RECALLED 帧 + MessageRecalled 消息体）
2. ✅ 任务 2 — proto 编译（Rust + Dart）
3. ✅ 任务 3 — 撤回接口（routes.rs）
4. ✅ 任务 4 — WS 广播 MESSAGE_RECALLED 帧（broadcaster.rs）
5. ✅ 任务 5 — 会话预览更新
6. ✅ 任务 6 — 编译验证 + 测试

---

## 任务 1：proto 扩展 `⬜`

文件：`proto/ws.proto`、`proto/message.proto`

ws.proto 新增帧类型：

```protobuf
enum WsFrameType {
  // ... 已有 0~15
  MESSAGE_RECALLED = 16;
}
```

message.proto 新增消息体：

```protobuf
message MessageRecalled {
  string message_id = 1;
  string conversation_id = 2;
  string sender_id = 3;
  string sender_name = 4;
}
```

---

## 任务 2：proto 编译 `⬜`

```bash
python scripts/proto/gen.py
```

生成 Rust 代码（cargo build 触发 prost-build）和 Dart 代码（protoc 生成到 flash_im_core）。

---

## 任务 3：撤回接口 `⬜`

文件：`server/modules/im-message/src/routes.rs`

新增路由：

```rust
.route("/conversations/{conv_id}/messages/{msg_id}/recall", post(recall_message))
```

handler 逻辑：

```rust
async fn recall_message(
    State(service): State<Arc<MessageService>>,
    headers: HeaderMap,
    Path((conv_id_str, msg_id_str)): Path<(String, String)>,
) -> Result<Json<serde_json::Value>, AppError> {
    let user_id = extract_user_id(&headers)?;
    let conv_id = Uuid::parse_str(&conv_id_str).map_err(|_| AppError::bad_request("无效的会话 ID"))?;
    let msg_id = Uuid::parse_str(&msg_id_str).map_err(|_| AppError::bad_request("无效的消息 ID"))?;

    // 1. 查消息
    // 2. 校验 sender_id == user_id
    // 3. 校验 created_at 在 2 分钟内
    // 4. 校验 status != 1
    // 5. UPDATE status = 1
    // 6. 更新会话预览
    // 7. 广播 MESSAGE_RECALLED
}
```

---

## 任务 4：WS 广播 MESSAGE_RECALLED `⬜`

文件：`server/modules/im-ws/src/dispatcher.rs` 或 `server/modules/im-message/src/routes.rs`

撤回成功后，构造 MessageRecalled protobuf，封装为 WsFrame，通过 WsState 广播给会话所有成员：

```rust
let recalled = im::MessageRecalled {
    message_id: msg_id.to_string(),
    conversation_id: conv_id.to_string(),
    sender_id: user_id.to_string(),
    sender_name: sender_name.clone(),
};
let frame = im::WsFrame {
    r#type: im::WsFrameType::MessageRecalled as i32,
    payload: recalled.encode_to_vec(),
};
// 广播给会话所有成员
for uid in member_ids {
    ws_state.send(uid, frame.clone());
}
```

---

## 任务 5：会话预览更新 `⬜`

文件：`server/modules/im-message/src/routes.rs`

撤回成功后，查询该会话最新消息更新预览：

```sql
UPDATE conversations SET last_message_preview = (
    SELECT CASE WHEN m.status = 1 THEN '撤回了一条消息'
           ELSE CASE m.type
               WHEN 1 THEN '[图片]'
               WHEN 2 THEN '[视频]'
               WHEN 3 THEN '[文件]'
               ELSE SUBSTRING(m.content, 1, 50)
           END END
    FROM messages m WHERE m.conversation_id = $1
    ORDER BY m.seq DESC LIMIT 1
), updated_at = NOW()
WHERE id = $1
```

---

## 任务 6：编译验证 + 测试 `⬜`

1. `cargo build` 通过
2. POST /messages/{id}/recall — 2 分钟内撤回成功（200）
3. POST /messages/{id}/recall — 超时撤回失败（403）
4. POST /messages/{id}/recall — 撤回别人的消息失败（403）
5. POST /messages/{id}/recall — 重复撤回失败（400）
6. 撤回后 GET /messages 返回 status=1
7. 撤回后会话预览更新
