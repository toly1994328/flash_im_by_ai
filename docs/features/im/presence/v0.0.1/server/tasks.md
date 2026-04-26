# 在线状态与已读回执 — 服务端任务清单

基于 [design.md](design.md) 设计，列出需要创建/修改的具体细节。

全局约束：
- 不新建 crate，所有改动在 im-ws 内完成
- 不新建数据库表，复用已有的 conversation_members.last_read_seq
- 已读回执在 handler 中直接操作数据库，不经过 MessageService
- WsHandlerState 新增 PgPool 字段
- 系统用户 id=0

---

## 执行顺序

1. ✅ 任务 1 — Proto 定义（4 个新帧类型 + 4 个新消息）
2. ✅ 任务 2 — WsState 多端连接改造
3. ✅ 任务 3 — dispatcher.rs 扩展（4 个新方法 + PgPool 查好友关系）
4. ✅ 任务 4 — handler.rs 扩展（上线/下线广播 + 在线列表 + READ_RECEIPT 处理）
5. ✅ 任务 5 — GET /conversations/{id}/read-seq + GET /conversations/{id}/messages/{mid}/read-status 接口
6. ✅ 任务 6 — 群详情接口扩展（成员返回 last_read_seq）
7. ✅ 任务 7 — 编译验证 + 测试（10/10 WS 测试通过）

---

## 任务 1：Proto 定义 `✅ 已完成`

### 1.1 ws.proto 新增帧类型 `✅`

文件：`proto/ws.proto`

```protobuf
enum WsFrameType {
    // ... 已有 0~11
    USER_ONLINE = 12;
    USER_OFFLINE = 13;
    ONLINE_LIST = 14;
    READ_RECEIPT = 15;
}
```

### 1.2 message.proto 新增消息 `✅`

文件：`proto/message.proto`

```protobuf
message UserStatusNotification {
    string user_id = 1;
}

message OnlineListNotification {
    repeated string user_ids = 1;
}

message ReadReceiptRequest {
    string conversation_id = 1;
    int64 read_seq = 2;
}

message ReadReceiptNotification {
    string conversation_id = 1;
    string user_id = 2;
    int64 read_seq = 3;
}
```

### 1.3 生成 Dart proto `✅`

```bash
protoc --dart_out=client/modules/flash_im_core/lib/src/data/proto proto/message.proto proto/ws.proto
```

生成后手动补 `clone() => deepCopy()` 方法（protoc_plugin 25.0.0 兼容性问题）。

---

## 任务 2：WsState 多端连接改造 `✅ 已完成`

文件：`server/modules/im-ws/src/state.rs`（重构）

### 2.1 ConnectionInfo 结构体 `✅`

```rust
pub struct ConnectionInfo {
    pub id: String,
    pub sender: WsSender,
}
```

### 2.2 connections 类型变更 `✅`

```rust
// 旧
connections: RwLock<HashMap<i64, WsSender>>

// 新
connections: RwLock<HashMap<i64, Vec<ConnectionInfo>>>
```

### 2.3 add 方法（返回 is_first） `✅`

```rust
pub async fn add(&self, user_id: i64, conn_id: String, sender: WsSender) -> bool {
    let mut conns = self.connections.write().await;
    let entry = conns.entry(user_id).or_insert_with(Vec::new);
    let is_first = entry.is_empty();
    entry.push(ConnectionInfo { id: conn_id, sender });
    is_first
}
```

### 2.4 remove 方法（返回 is_last） `✅`

```rust
pub async fn remove(&self, user_id: i64, conn_id: &str) -> bool {
    let mut conns = self.connections.write().await;
    let mut is_last = false;
    if let Some(user_conns) = conns.get_mut(&user_id) {
        user_conns.retain(|c| c.id != conn_id);
        if user_conns.is_empty() {
            conns.remove(&user_id);
            is_last = true;
        }
    }
    is_last
}
```

### 2.5 send_to_user 适配（发给所有端） `✅`

```rust
pub async fn send_to_user(&self, user_id: i64, data: Vec<u8>) {
    let conns = self.connections.read().await;
    if let Some(user_conns) = conns.get(&user_id) {
        for conn in user_conns {
            let _ = conn.sender.send(data.clone());
        }
    }
}
```

### 2.6 新增 is_online / get_online_users `✅`

```rust
pub async fn is_online(&self, user_id: i64) -> bool {
    self.connections.read().await.contains_key(&user_id)
}

pub async fn get_online_users(&self) -> Vec<i64> {
    self.connections.read().await.keys().copied().collect()
}
```

---

## 任务 3：dispatcher.rs 扩展 `✅ 已完成`

文件：`server/modules/im-ws/src/dispatcher.rs`（修改）

### 3.1 broadcast_user_online `✅`

实际实现改为只通知在线好友（查 friend_relations 取交集）：

```rust
pub async fn broadcast_user_online(&self, user_id: i64) {
    let friend_ids = self.get_online_friend_ids(user_id).await;
    if friend_ids.is_empty() { return; }
    let notification = UserStatusNotification { user_id: user_id.to_string() };
    let frame = WsFrame { r#type: WsFrameType::UserOnline as i32, payload: notification.encode_to_vec() };
    self.ws_state.send_to_users(&friend_ids, frame.encode_to_vec()).await;
}
```

### 3.2 broadcast_user_offline `✅`

同样只通知在线好友：

```rust
pub async fn broadcast_user_offline(&self, user_id: i64) {
    let friend_ids = self.get_online_friend_ids(user_id).await;
    if friend_ids.is_empty() { return; }
    // ... 同上模式
}
```

### 3.3 send_online_list `✅`

只返回在线好友列表（不是所有在线用户）：

```rust
pub async fn send_online_list(&self, user_id: i64) {
    let friend_ids = self.get_online_friend_ids(user_id).await;
    let user_ids: Vec<String> = friend_ids.iter().map(|id| id.to_string()).collect();
    // ...
}
```

### 3.4 broadcast_read_receipt `✅`

```rust
pub async fn broadcast_read_receipt(
    &self, conversation_id: &str, user_id: i64, read_seq: i64, member_ids: &[i64],
) {
    let targets: Vec<i64> = member_ids.iter().filter(|&&id| id != user_id).copied().collect();
    self.ws_state.send_to_users(&targets, frame.encode_to_vec()).await;
}
```

### 3.5 新增 get_online_friend_ids 辅助方法 `✅`

```rust
async fn get_online_friend_ids(&self, user_id: i64) -> Vec<i64> {
    let friend_rows: Vec<(i64,)> = sqlx::query_as(
        "SELECT friend_id FROM friend_relations WHERE user_id = $1"
    ).bind(user_id).fetch_all(&self.db).await.unwrap_or_default();
    let online_set: HashSet<i64> = self.ws_state.get_online_users().await.into_iter().collect();
    friend_rows.into_iter().map(|(id,)| id).filter(|id| online_set.contains(id)).collect()
}
```

### 3.6 import 新增 `✅`

```rust
use crate::proto::{
    UserStatusNotification, OnlineListNotification, ReadReceiptNotification,
};
```

---

## 任务 4：handler.rs 扩展 `✅ 已完成`

文件：`server/modules/im-ws/src/handler.rs`（修改）

### 4.1 WsHandlerState 新增 PgPool `✅`

```rust
pub struct WsHandlerState {
    pub ws_state: Arc<WsState>,
    pub dispatcher: Arc<MessageDispatcher>,
    pub db: sqlx::PgPool,
}
```

### 4.2 handle_socket 生成 conn_id `✅`

```rust
let conn_id = Uuid::new_v4().to_string();
```

### 4.3 认证成功后：注册连接 + 上线广播 + 在线列表 `✅`

```rust
let is_first = state.ws_state.add(user_id, conn_id.clone(), tx).await;
if is_first { state.dispatcher.broadcast_user_online(user_id).await; }
state.dispatcher.send_online_list(user_id).await;
```

### 4.4 断连后：移除连接 + 下线广播 `✅`

```rust
let is_last = state.ws_state.remove(user_id, &conn_id).await;
if is_last { state.dispatcher.broadcast_user_offline(user_id).await; }
```

### 4.5 帧分发新增 READ_RECEIPT `✅`

```rust
WsFrameType::ReadReceipt => {
    handle_read_receipt(user_id, &frame.payload, &state).await;
}
```

### 4.6 handle_read_receipt 函数 `✅`

```rust
async fn handle_read_receipt(user_id: i64, payload: &[u8], state: &WsHandlerState) {
    // 1. UPDATE last_read_seq = GREATEST(last_read_seq, $3)
    // 2. 重新计算 unread_count（SELECT COUNT(*) FROM messages WHERE seq > last_read_seq）
    // 3. 查询会话成员，broadcast_read_receipt
}
```

### 4.7 import 新增 `✅`

```rust
use crate::proto::ReadReceiptRequest;
use uuid::Uuid;
```

---

## 任务 5：HTTP 接口 `✅ 已完成`

文件：`server/modules/im-message/src/routes.rs`

### 5.1 GET /conversations/{id}/read-seq `✅`

进入聊天页时调一次，返回会话成员的已读位置（排除自己）。

```rust
.route("/conversations/{conv_id}/read-seq", get(get_read_seq))
```

### 5.2 GET /conversations/{id}/messages/{mid}/read-status `✅`

点击"N人已读"时调，返回已读/未读成员列表。

```rust
.route("/conversations/{conv_id}/messages/{msg_id}/read-status", get(get_read_status))
```

---

## 任务 6：群详情接口扩展 `✅ 已完成`

文件：`server/modules/im-group/src/repository.rs`

### 6.1 get_group_members 返回 last_read_seq `✅`

GroupMember 模型新增 `last_read_seq: i64` 字段。

---

## 任务 7：编译验证 + 测试 `✅ 已完成`

### 7.1 编译 `✅`

`cargo build` 通过。

### 7.2 main.rs 适配 `✅`

WsHandlerState 构建时传入 PgPool，dispatcher 构建时也传入 PgPool。

### 7.3 WS 测试脚本 `✅`

`docs/features/im/presence/api/test_presence.py` — 10/10 全部通过：

| # | 测试项 | 结果 |
|---|--------|------|
| 1 | 用户1 WS 认证 | ✅ |
| 2 | 用户1 收到 ONLINE_LIST（空） | ✅ |
| 3 | 用户2 WS 认证 | ✅ |
| 4 | 用户2 收到 ONLINE_LIST（含用户1） | ✅ |
| 5 | 用户1 收到 USER_ONLINE（用户2） | ✅ |
| 6 | 用户2 发送 READ_RECEIPT | ✅ |
| 7 | 用户1 收到 READ_RECEIPT 通知 | ✅ |
| 8 | GET /read-seq 返回正确 | ✅ |
| 9 | GET /read-status 返回正确 | ✅ |
| 10 | 用户2 断开，用户1 收到 USER_OFFLINE | ✅ |
