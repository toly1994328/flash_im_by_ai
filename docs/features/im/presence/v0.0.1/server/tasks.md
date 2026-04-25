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

1. ⬜ 任务 1 — Proto 定义（4 个新帧类型 + 4 个新消息）
2. ⬜ 任务 2 — WsState 多端连接改造
3. ⬜ 任务 3 — dispatcher.rs 扩展（4 个新方法）
4. ⬜ 任务 4 — handler.rs 扩展（上线/下线广播 + 在线列表 + READ_RECEIPT 处理）
5. ⬜ 任务 5 — GET /conversations/{id}/messages/{mid}/read-status 接口
6. ⬜ 任务 6 — 群详情接口扩展（成员返回 last_read_seq）
7. ⬜ 任务 7 — 编译验证 + 测试

---

## 任务 1：Proto 定义 `⬜ 待处理`

### 1.1 ws.proto 新增帧类型 `⬜`

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

### 1.2 message.proto 新增消息 `⬜`

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

### 1.3 生成 Dart proto `⬜`

```bash
protoc --dart_out=client/modules/flash_im_core/lib/src/data/proto proto/message.proto proto/ws.proto
```

生成后手动补 `clone() => deepCopy()` 方法（protoc_plugin 25.0.0 兼容性问题）。

---

## 任务 2：WsState 多端连接改造 `⬜ 待处理`

文件：`server/modules/im-ws/src/state.rs`（重构）

### 2.1 ConnectionInfo 结构体 `⬜`

```rust
pub struct ConnectionInfo {
    pub id: String,
    pub sender: WsSender,
}
```

### 2.2 connections 类型变更 `⬜`

```rust
// 旧
connections: RwLock<HashMap<i64, WsSender>>

// 新
connections: RwLock<HashMap<i64, Vec<ConnectionInfo>>>
```

### 2.3 add 方法（返回 is_first） `⬜`

```rust
pub async fn add(&self, user_id: i64, conn_id: String, sender: WsSender) -> bool {
    let mut conns = self.connections.write().await;
    let entry = conns.entry(user_id).or_insert_with(Vec::new);
    let is_first = entry.is_empty();
    entry.push(ConnectionInfo { id: conn_id, sender });
    is_first
}
```

### 2.4 remove 方法（返回 is_last） `⬜`

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

### 2.5 send_to_user 适配（发给所有端） `⬜`

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

### 2.6 新增 is_online / get_online_users `⬜`

```rust
pub async fn is_online(&self, user_id: i64) -> bool {
    self.connections.read().await.contains_key(&user_id)
}

pub async fn get_online_users(&self) -> Vec<i64> {
    self.connections.read().await.keys().copied().collect()
}
```

---

## 任务 3：dispatcher.rs 扩展 `⬜ 待处理`

文件：`server/modules/im-ws/src/dispatcher.rs`（修改）

### 3.1 broadcast_user_online `⬜`

```rust
pub async fn broadcast_user_online(&self, user_id: i64) {
    let notification = UserStatusNotification { user_id: user_id.to_string() };
    let frame = WsFrame { r#type: WsFrameType::UserOnline as i32, payload: notification.encode_to_vec() };
    let online_users = self.ws_state.get_online_users().await;
    self.ws_state.send_to_users(&online_users, frame.encode_to_vec()).await;
    println!("📡 [dispatcher] user {} online, notified {} users", user_id, online_users.len());
}
```

### 3.2 broadcast_user_offline `⬜`

```rust
pub async fn broadcast_user_offline(&self, user_id: i64) {
    let notification = UserStatusNotification { user_id: user_id.to_string() };
    let frame = WsFrame { r#type: WsFrameType::UserOffline as i32, payload: notification.encode_to_vec() };
    let online_users = self.ws_state.get_online_users().await;
    self.ws_state.send_to_users(&online_users, frame.encode_to_vec()).await;
    println!("📡 [dispatcher] user {} offline, notified {} users", user_id, online_users.len());
}
```

### 3.3 send_online_list `⬜`

```rust
pub async fn send_online_list(&self, user_id: i64) {
    let online_users = self.ws_state.get_online_users().await;
    let user_ids: Vec<String> = online_users.iter()
        .filter(|&&id| id != user_id)
        .map(|id| id.to_string())
        .collect();
    let notification = OnlineListNotification { user_ids };
    let frame = WsFrame { r#type: WsFrameType::OnlineList as i32, payload: notification.encode_to_vec() };
    self.ws_state.send_to_user(user_id, frame.encode_to_vec()).await;
    println!("📡 [dispatcher] sent online list to user {} ({} users)", user_id, online_users.len() - 1);
}
```

### 3.4 broadcast_read_receipt `⬜`

```rust
pub async fn broadcast_read_receipt(
    &self,
    conversation_id: &str,
    user_id: i64,
    read_seq: i64,
    member_ids: &[i64],
) {
    let notification = ReadReceiptNotification {
        conversation_id: conversation_id.to_string(),
        user_id: user_id.to_string(),
        read_seq,
    };
    let frame = WsFrame { r#type: WsFrameType::ReadReceipt as i32, payload: notification.encode_to_vec() };
    // 排除上报者自己
    let targets: Vec<i64> = member_ids.iter().filter(|&&id| id != user_id).copied().collect();
    self.ws_state.send_to_users(&targets, frame.encode_to_vec()).await;
}
```

### 3.5 import 新增 `⬜`

dispatcher.rs 的 import 中新增：

```rust
use crate::proto::{
    // ... 已有
    UserStatusNotification, OnlineListNotification, ReadReceiptNotification,
};
```

---

## 任务 4：handler.rs 扩展 `⬜ 待处理`

文件：`server/modules/im-ws/src/handler.rs`（修改）

### 4.1 WsHandlerState 新增 PgPool `⬜`

```rust
pub struct WsHandlerState {
    pub ws_state: Arc<WsState>,
    pub dispatcher: Arc<MessageDispatcher>,
    pub db: PgPool,  // 新增：已读回执需要操作数据库
}
```

同步修改 main.rs 中 WsHandlerState 的构建。

### 4.2 handle_socket 生成 conn_id `⬜`

```rust
async fn handle_socket(socket: WebSocket, state: Arc<WsHandlerState>) {
    let conn_id = uuid::Uuid::new_v4().to_string();
    // ...
}
```

### 4.3 认证成功后：注册连接 + 上线广播 + 在线列表 `⬜`

```rust
// 注册连接（返回是否首次上线）
let is_first = state.ws_state.add(user_id, conn_id.clone(), tx).await;

// 首次上线广播
if is_first {
    state.dispatcher.broadcast_user_online(user_id).await;
}

// 推送在线列表
state.dispatcher.send_online_list(user_id).await;
```

### 4.4 断连后：移除连接 + 下线广播 `⬜`

```rust
// 清理（传入 conn_id）
let is_last = state.ws_state.remove(user_id, &conn_id).await;

// 完全下线广播
if is_last {
    state.dispatcher.broadcast_user_offline(user_id).await;
}
```

### 4.5 帧分发新增 READ_RECEIPT `⬜`

在接收循环的 match 中新增：

```rust
WsFrameType::ReadReceipt => {
    handle_read_receipt(user_id, &frame.payload, &state).await;
}
```

### 4.6 handle_read_receipt 函数 `⬜`

```rust
async fn handle_read_receipt(user_id: i64, payload: &[u8], state: &WsHandlerState) {
    let req = match ReadReceiptRequest::decode(payload) {
        Ok(r) => r,
        Err(_) => return,
    };
    let conv_id = match Uuid::parse_str(&req.conversation_id) {
        Ok(id) => id,
        Err(_) => return,
    };

    // 1. 更新 last_read_seq（GREATEST 防止回退）
    let _ = sqlx::query(
        "UPDATE conversation_members \
         SET last_read_seq = GREATEST(last_read_seq, $3) \
         WHERE conversation_id = $1 AND user_id = $2"
    )
    .bind(conv_id)
    .bind(user_id)
    .bind(req.read_seq)
    .execute(&state.db)
    .await;

    // 2. 重新计算 unread_count
    let _ = sqlx::query(
        "UPDATE conversation_members cm \
         SET unread_count = ( \
             SELECT COUNT(*) FROM messages m \
             WHERE m.conversation_id = cm.conversation_id \
               AND m.seq > cm.last_read_seq \
               AND m.sender_id != cm.user_id \
         ) \
         WHERE cm.conversation_id = $1 AND cm.user_id = $2"
    )
    .bind(conv_id)
    .bind(user_id)
    .execute(&state.db)
    .await;

    // 3. 查询会话其他成员，推送已读通知
    let member_rows: Vec<(i64,)> = sqlx::query_as(
        "SELECT user_id FROM conversation_members \
         WHERE conversation_id = $1 AND is_deleted = false"
    )
    .bind(conv_id)
    .fetch_all(&state.db)
    .await
    .unwrap_or_default();

    let member_ids: Vec<i64> = member_rows.into_iter().map(|(id,)| id).collect();
    state.dispatcher.broadcast_read_receipt(
        &req.conversation_id, user_id, req.read_seq, &member_ids,
    ).await;
}
```

### 4.7 import 新增 `⬜`

handler.rs 的 import 中新增：

```rust
use crate::proto::ReadReceiptRequest;
use uuid::Uuid;
use sqlx::PgPool;
```

---

## 任务 5：GET /conversations/{id}/messages/{mid}/read-status 接口 `⬜ 待处理`

文件：`server/modules/im-message/src/routes.rs`（或新建 read_status handler）

### 5.1 路由注册 `⬜`

```rust
.route("/conversations/{conv_id}/messages/{msg_id}/read-status", get(get_read_status))
```

### 5.2 handler 实现 `⬜`

```rust
async fn get_read_status(headers, Path((conv_id, msg_id)), State(state)):
    user_id = extract_user_id(headers)?

    // 1. 查消息的 seq
    msg_seq = SELECT seq FROM messages WHERE id = msg_id AND conversation_id = conv_id

    // 2. 查所有活跃成员的 last_read_seq（排除消息发送者）
    members = SELECT cm.user_id, cm.last_read_seq, up.nickname, up.avatar
              FROM conversation_members cm
              LEFT JOIN user_profiles up ON cm.user_id = up.account_id
              WHERE cm.conversation_id = conv_id AND cm.is_deleted = false
              AND cm.user_id != sender_id

    // 3. 分组：last_read_seq >= msg_seq → read，否则 → unread
    return { read_members: [...], unread_members: [...] }
```

---

## 任务 6：群详情接口扩展 `⬜ 待处理`

文件：`server/modules/im-group/src/repository.rs`（修改 get_group_members）

### 6.1 get_group_members 返回 last_read_seq `⬜`

```sql
SELECT cm.user_id, COALESCE(up.nickname, '未知用户') AS nickname, up.avatar, cm.last_read_seq
FROM conversation_members cm
LEFT JOIN user_profiles up ON cm.user_id = up.account_id
JOIN conversations c ON c.id = cm.conversation_id
WHERE cm.conversation_id = $1 AND cm.is_deleted = false
ORDER BY CASE WHEN cm.user_id = c.owner_id THEN 0 ELSE 1 END, cm.joined_at
```

GroupMember 模型新增 `last_read_seq: i64` 字段。

---

## 任务 7：编译验证 + 测试 `⬜ 待处理`

### 5.1 编译 `⬜`

```bash
cargo build
```

### 5.2 main.rs 适配 `⬜`

WsHandlerState 构建时传入 PgPool：

```rust
let ws_handler_state = Arc::new(WsHandlerState {
    ws_state: ws_state.clone(),
    dispatcher: dispatcher.clone(),
    db: pool.clone(),
});
```

### 5.3 手动测试路径 `⬜`

1. 用户 A 登录 → 观察终端打印 "user X online"
2. 用户 B 登录 → B 收到 ONLINE_LIST（含 A）→ A 收到 USER_ONLINE（B 的 ID）
3. 用户 B 断开 → A 收到 USER_OFFLINE（B 的 ID）
4. 用户 A 打开和 B 的聊天页 → 前端发送 READ_RECEIPT → 数据库 last_read_seq 更新
5. 用户 B 收到 READ_RECEIPT 通知 → B 的 ChatPage 显示已读标记
