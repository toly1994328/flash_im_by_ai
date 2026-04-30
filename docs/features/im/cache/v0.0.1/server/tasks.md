# 本地缓存与离线同步 — 服务端任务清单

基于 [design.md](design.md) 设计。后端改动很小，只需要给消息查询接口加 after_seq 参数。

---

## 执行顺序

1. ✅ 任务 1 — MessageQuery 新增 after_seq 字段
2. ✅ 任务 2 — Repository 新增 find_after_with_sender 方法
3. ✅ 任务 3 — Service get_history 支持 after_seq
4. ✅ 任务 4 — 路由层适配
5. ✅ 任务 5 — 编译验证 + 测试

---

## 任务 1：MessageQuery 新增 after_seq `✅`

文件：`server/modules/im-message/src/models.rs`

```rust
pub struct MessageQuery {
    pub before_seq: Option<i64>,
    pub after_seq: Option<i64>,   // 新增
    #[serde(default = "default_limit")]
    pub limit: i32,
}
```

---

## 任务 2：Repository 新增 find_after_with_sender `✅`

文件：`server/modules/im-message/src/repository.rs`

```rust
pub async fn find_after_with_sender(
    &self, conversation_id: Uuid, after_seq: i64, limit: i32,
) -> Result<Vec<MessageWithSender>, sqlx::Error> {
    sqlx::query_as(
        "SELECT m.id, m.conversation_id, m.sender_id, \
            COALESCE(up.nickname, '?') AS sender_name, up.avatar AS sender_avatar, \
            m.seq, m.type AS msg_type, m.content, m.extra, m.status, m.created_at \
         FROM messages m \
         LEFT JOIN user_profiles up ON up.account_id = m.sender_id \
         WHERE m.conversation_id = $1 AND m.seq > $2 \
         ORDER BY m.seq ASC \
         LIMIT $3"
    )
    .bind(conversation_id).bind(after_seq).bind(limit)
    .fetch_all(&self.pool).await
}
```

---

## 任务 3：Service get_history 支持 after_seq `✅`

文件：`server/modules/im-message/src/service.rs`

```rust
pub async fn get_history(
    &self, conversation_id: Uuid,
    before_seq: Option<i64>, after_seq: Option<i64>, limit: i32,
) -> Result<Vec<MessageWithSender>, StatusCode> {
    let limit = limit.min(100).max(1);
    let messages = match (after_seq, before_seq) {
        (Some(seq), _) => self.repo.find_after_with_sender(conversation_id, seq, limit).await,
        (_, Some(seq)) => self.repo.find_before_with_sender(conversation_id, seq, limit).await,
        _ => self.repo.find_latest_with_sender(conversation_id, limit).await,
    };
    messages.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)
}
```

---

## 任务 4：路由层适配 `✅`

文件：`server/modules/im-message/src/routes.rs`

```rust
let messages = service.get_history(conv_id, query.before_seq, query.after_seq, query.limit).await?;
```

---

## 任务 5：编译验证 + 测试 `✅`

1. `cargo build` 通过
2. GET /messages（无参数）→ 返回最新消息（行为不变）
3. GET /messages?before_seq=10 → 返回 seq < 10 的消息（行为不变）
4. GET /messages?after_seq=5 → 返回 seq > 5 的消息（新功能）
5. GET /messages?after_seq=5&before_seq=10 → after_seq 优先
