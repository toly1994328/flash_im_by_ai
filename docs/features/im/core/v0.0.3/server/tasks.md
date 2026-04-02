# IM Core v0.0.3 — 服务端任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。
本版本实现文本消息的完整收发链路：存储、序列号、广播、ACK、会话更新推送、历史查询。

---

## 执行顺序

1. ✅ 任务 1 — 协议扩展（ws.proto + message.proto）
2. ✅ 任务 2 — 数据库迁移（messages + conversation_seq）
3. ✅ 任务 3 — im-message crate 骨架 + 依赖
4. ✅ 任务 4 — models.rs 数据模型
5. ✅ 任务 5 — seq.rs 序列号生成器
6. ✅ 任务 6 — repository.rs 数据库操作
7. ✅ 任务 7 — broadcast.rs 广播器 trait
8. ✅ 任务 8 — service.rs 业务逻辑
9. ✅ 任务 9 — routes.rs HTTP 路由
10. ✅ 任务 10 — lib.rs 导出 + workspace 注册
11. ✅ 任务 11 — im-conversation 扩展
12. ✅ 任务 12 — im-ws 帧分发扩展
13. ✅ 任务 13 — main.rs 集成
14. ✅ 任务 14 — 编译验证
15. ✅ 任务 15 — Python WebSocket 测试客户端
16. ✅ 任务 16 — Link Test Writer（HTTP 接口文档）

---

## 任务 1：协议扩展 `✅`

### 1.1 ws.proto 扩展 `✅`

文件：`proto/ws.proto`（修改）

WsFrameType 枚举新增：
```protobuf
CHAT_MESSAGE = 4;
MESSAGE_ACK = 5;
CONVERSATION_UPDATE = 6;
```

### 1.2 message.proto 新建 `✅`

文件：`proto/message.proto`（新建）

定义：
- MessageType 枚举（TEXT=0）— 本版本只有文本
- MessageStatus 枚举（NORMAL=0, RECALLED=1, DELETED=2）
- ChatMessage（id, conversation_id, sender_id, seq, type, content, extra, status, created_at, sender_name, sender_avatar）
- SendMessageRequest（conversation_id, type, content, extra, client_id）
- MessageAck（message_id, seq）
- ConversationUpdate（conversation_id, last_message_preview, last_message_at, unread_count, total_unread）

### 1.3 代码生成 `✅`

运行 `scripts/proto/gen.ps1` 重新生成前后端代码。
后端 build.rs 需要新增 message.proto 的编译。

---

## 任务 2：数据库迁移 `✅`

文件：`server/migrations/20260330_003_messages.sql`（新建）

```sql
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id),
    sender_id BIGINT NOT NULL,
    seq BIGINT NOT NULL,
    type SMALLINT NOT NULL DEFAULT 0,
    content TEXT NOT NULL,
    extra JSONB,
    status SMALLINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation_seq ON messages(conversation_id, seq DESC);

CREATE TABLE conversation_seq (
    conversation_id UUID PRIMARY KEY REFERENCES conversations(id),
    current_seq BIGINT NOT NULL DEFAULT 0
);
```

更新 `scripts/server/reset_db.ps1` 新增执行此迁移文件。

---

## 任务 3：im-message crate 骨架 `✅`

文件：`server/modules/im-message/Cargo.toml`（新建）

workspace 注册：`server/Cargo.toml` 的 members 新增 `"modules/im-message"`。

---

## 任务 4：models.rs `✅`

文件：`server/modules/im-message/src/models.rs`（新建）

核心结构体：Message、NewMessage、MessageWithSender、MessageQuery、generate_preview()

---

## 任务 5：seq.rs 序列号生成器 `✅`

文件：`server/modules/im-message/src/seq.rs`（新建）

SeqGenerator：原子递增 conversation_seq，UPDATE ... RETURNING + INSERT ON CONFLICT。

---

## 任务 6：repository.rs `✅`

文件：`server/modules/im-message/src/repository.rs`（新建）

create、find_before_with_sender、find_latest_with_sender。

---

## 任务 7：broadcast.rs 广播器 trait `✅`

文件：`server/modules/im-message/src/broadcast.rs`（新建）

MessageBroadcaster trait + NoopBroadcaster。

---

## 任务 8：service.rs `✅`

文件：`server/modules/im-message/src/service.rs`（新建）

send()：验证 → 生成 seq → 存储 → 更新便签 → 广播。
get_history()：基于 before_seq 分页查询。

---

## 任务 9：routes.rs HTTP 路由 `✅`

文件：`server/modules/im-message/src/routes.rs`（新建）

GET /conversations/:id/messages?before_seq=&limit=

---

## 任务 10：lib.rs 导出 + workspace 注册 `✅`

文件：`server/modules/im-message/src/lib.rs`（新建）

---

## 任务 11：im-conversation 扩展 `✅`

文件：`server/modules/im-conversation/src/service.rs`（修改）

新增：update_last_message、increment_unread、get_member_ids、is_member。

---

## 任务 12：im-ws 帧分发扩展 `✅`

- dispatcher.rs 重写：持有 MessageService，处理 CHAT_MESSAGE 帧
- state.rs 新建：WsState（mpsc channel 管理在线用户）
- broadcaster.rs 新建：WsBroadcaster（实现 MessageBroadcaster trait）
- handler.rs 重构：channel 模式 + tokio::select! 双向循环

---

## 任务 13：main.rs 集成 `✅`

创建 WsState → WsBroadcaster → MessageService → MessageDispatcher → WsHandlerState。

---

## 任务 14：编译验证 `✅`

cargo build 通过。

---

## 任务 15：Python WebSocket 测试客户端 `✅`

文件：`docs/features/im/core/v0.0.3/test/ws_chat_test.py`

全链路测试通过：登录 → 连接 → 认证 → 发消息 → ACK → 对方收到 → 会话更新 → 历史查询 → seq 递增。

---

## 任务 16：Link Test Writer `✅`

文件：`docs/features/im/core/api/message/request/conversation_message.py`

HTTP 历史消息接口测试 + 文档生成。
