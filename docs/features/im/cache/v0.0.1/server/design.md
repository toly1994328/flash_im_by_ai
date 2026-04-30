---
module: im-message
version: v0.0.1_cache
date: 2026-04-28
tags: [本地缓存, 增量同步, after_seq]
---

# 本地缓存与离线同步 — 服务端设计报告

> 关联设计：[功能分析](../analysis.md)

## 1. 目标

- GET /conversations/{id}/messages 新增 `after_seq` 查询参数，支持"拉本地没有的新消息"
- 现有 `before_seq` 是"向上翻页（拉更早的旧消息）"，`after_seq` 是"向下同步（拉比本地更新的消息）"

## 2. 现状分析

### 已有能力

- `GET /conversations/{id}/messages?before_seq=N&limit=50`：返回 seq < N 的消息，按 seq 降序，用于向上翻页
- `GET /conversations/{id}/messages`（无 before_seq）：返回最新的 N 条消息

### 缺失

- 无法查询 seq > N 的消息（增量同步需要）

## 3. 改动

### MessageQuery 新增 after_seq

```rust
// ---> server/modules/im-message/src/models.rs
#[derive(Debug, Deserialize)]
pub struct MessageQuery {
    pub before_seq: Option<i64>,
    pub after_seq: Option<i64>,   // 新增
    #[serde(default = "default_limit")]
    pub limit: i32,
}
```

### get_history 支持 after_seq

```rust
// ---> server/modules/im-message/src/service.rs
pub async fn get_history(&self, conversation_id: Uuid, before_seq: Option<i64>, after_seq: Option<i64>, limit: i32):
    if after_seq is Some:
        return repo.find_after_with_sender(conversation_id, after_seq, limit)  // seq > after_seq, ORDER BY seq ASC
    if before_seq is Some:
        return repo.find_before_with_sender(conversation_id, before_seq, limit)  // seq < before_seq, ORDER BY seq DESC
    return repo.find_latest_with_sender(conversation_id, limit)  // 最新 N 条
```

### 新增 Repository 方法

```sql
-- find_after_with_sender: 拉比 after_seq 更新的消息
SELECT m.*, COALESCE(up.nickname, '?') AS sender_name, up.avatar AS sender_avatar
FROM messages m
LEFT JOIN user_profiles up ON up.account_id = m.sender_id
WHERE m.conversation_id = $1 AND m.seq > $2 AND m.status != 2
ORDER BY m.seq ASC
LIMIT $3
```

注意排序是 ASC（从旧到新），和 before_seq 的 DESC 相反。客户端拿到后追加到本地消息列表末尾。

### 路由层适配

```rust
// ---> server/modules/im-message/src/routes.rs
let messages = service.get_history(conv_id, query.before_seq, query.after_seq, query.limit).await?;
```

## 4. 设计决策

| 决策 | 方案 | 理由 |
|------|------|------|
| after_seq 和 before_seq 互斥 | 同时传时 after_seq 优先 | 不会同时需要"向上翻页"和"向下同步" |
| after_seq 排序 ASC | seq > N ORDER BY seq ASC | 增量同步要从旧到新，追加到本地末尾 |
| 不新建接口 | 复用 GET /messages，加参数 | 保持接口简洁，一个端点覆盖三种场景 |

## 5. 验收标准

| 验收条件 | 验收方式 |
|----------|----------|
| after_seq 返回 seq > N 的消息 | HTTP 请求 |
| after_seq 排序为 ASC | 检查响应顺序 |
| before_seq 行为不变 | 回归测试 |
| 无参数行为不变（返回最新 N 条） | 回归测试 |
