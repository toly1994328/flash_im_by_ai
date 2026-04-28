# 综合搜索 — 服务端任务清单

基于 [design.md](design.md) 设计，列出需要创建/修改的具体细节。

全局约束：
- 不新建 crate，搜索接口分布在 im-friend、im-conversation、im-message 中
- 不新建数据库表
- 搜索用 ILIKE + 通配符转义
- 只搜文本消息（msg_type = 0）
- 过滤系统消息（sender_id != 0）

---

## 执行顺序

1. ✅ 任务 1 — GET /api/friends/search（im-friend）
2. ✅ 任务 2 — GET /api/conversations/search-joined-groups（im-conversation）
3. ✅ 任务 3 — GET /api/messages/search（im-message）
4. ✅ 任务 4 — GET /conversations/{id}/messages/search（im-message）
5. ✅ 任务 5 — 编译验证 + 测试（9/9 通过）

---

## 任务 1：GET /api/friends/search `⬜ 待处理`

文件：`server/modules/im-friend/src/api.rs`（修改）

### 1.1 新增查询参数结构 `⬜`

```rust
#[derive(Deserialize)]
struct SearchQuery {
    keyword: String,
    #[serde(default = "default_search_limit")]
    limit: i32,
}
fn default_search_limit() -> i32 { 20 }
```

### 1.2 新增 handler `⬜`

```rust
/// GET /api/friends/search — 搜索好友
async fn search_friends(
    State(state): State<FriendApiState>,
    headers: HeaderMap,
    Query(query): Query<SearchQuery>,
) -> ApiResult {
    let user_id = extract_user_id(&headers)?;
    let keyword = query.keyword.replace('%', "\\%").replace('_', "\\_");
    let pattern = format!("%{}%", keyword);
    let limit = query.limit.min(50).max(1);

    let rows: Vec<(i64, String, Option<String>)> = sqlx::query_as(
        "SELECT fr.friend_id, COALESCE(up.nickname, '?') AS nickname, up.avatar \
         FROM friend_relations fr \
         LEFT JOIN user_profiles up ON up.account_id = fr.friend_id \
         WHERE fr.user_id = $1 AND up.nickname ILIKE $2 \
         ORDER BY up.nickname \
         LIMIT $3"
    )
    .bind(user_id).bind(&pattern).bind(limit)
    .fetch_all(state.service.repo().pool())
    .await.map_err(|e| err_response_internal(e))?;

    let data: Vec<serde_json::Value> = rows.into_iter().map(|(id, nickname, avatar)| {
        serde_json::json!({ "friend_id": id.to_string(), "nickname": nickname, "avatar": avatar })
    }).collect();

    Ok(Json(serde_json::json!({ "data": data })))
}
```

### 1.3 注册路由 `⬜`

```rust
.route("/api/friends/search", get(search_friends))
```

---

## 任务 2：GET /api/conversations/search-joined-groups `⬜ 待处理`

文件：`server/modules/im-conversation/src/routes.rs`（修改）

### 2.1 新增 handler `⬜`

```rust
/// GET /api/conversations/search-joined-groups — 搜索已加入的群聊
async fn search_joined_groups(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Query(params): Query<HashMap<String, String>>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let keyword = params.get("keyword").cloned().unwrap_or_default();
    let limit: i32 = params.get("limit").and_then(|v| v.parse().ok()).unwrap_or(20).min(50).max(1);

    let escaped = keyword.replace('%', "\\%").replace('_', "\\_");
    let pattern = format!("%{}%", escaped);

    let rows: Vec<(Uuid, Option<String>, Option<String>, i64)> = sqlx::query_as(
        "SELECT c.id, c.name, c.avatar, \
            (SELECT COUNT(*) FROM conversation_members WHERE conversation_id = c.id AND is_deleted = false) AS member_count \
         FROM conversations c \
         INNER JOIN conversation_members cm ON cm.conversation_id = c.id AND cm.user_id = $1 AND cm.is_deleted = false \
         WHERE c.type = 1 AND COALESCE(c.status, 0::SMALLINT) = 0 AND c.name ILIKE $2 \
         ORDER BY c.name \
         LIMIT $3"
    )
    .bind(user_id).bind(&pattern).bind(limit)
    .fetch_all(&state.db)
    .await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let data: Vec<serde_json::Value> = rows.into_iter().map(|(id, name, avatar, count)| {
        serde_json::json!({
            "conversation_id": id.to_string(),
            "name": name,
            "avatar": avatar,
            "member_count": count,
        })
    }).collect();

    Ok(Json(serde_json::json!({ "data": data })))
}
```

### 2.2 注册路由 `⬜`

```rust
.route("/api/conversations/search-joined-groups", get(search_joined_groups))
```

注意：这个路由需要 `use std::collections::HashMap;` 和 `use uuid::Uuid;`。

---

## 任务 3：GET /api/messages/search `⬜ 待处理`

文件：`server/modules/im-message/src/routes.rs`（修改）

### 3.1 新增查询参数 `⬜`

```rust
#[derive(Deserialize)]
struct SearchQuery {
    keyword: String,
    #[serde(default = "default_search_limit")]
    limit: i32,
}
fn default_search_limit() -> i32 { 10 }
```

### 3.2 新增 handler `⬜`

分两步查询：

```rust
/// GET /api/messages/search — 跨会话消息搜索
async fn search_messages(
    State(service): State<Arc<MessageService>>,
    headers: HeaderMap,
    Query(query): Query<SearchQuery>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let user_id = extract_user_id(&headers)?;
    let keyword = query.keyword.replace('%', "\\%").replace('_', "\\_");
    let pattern = format!("%{}%", keyword);
    let limit = query.limit.min(20).max(1);

    // 第一步：找匹配的会话及匹配数
    let groups: Vec<(Uuid, i64)> = sqlx::query_as(
        "SELECT m.conversation_id, COUNT(*) AS match_count \
         FROM messages m \
         INNER JOIN conversation_members cm ON cm.conversation_id = m.conversation_id AND cm.user_id = $1 AND cm.is_deleted = false \
         WHERE m.type = 0 AND m.content ILIKE $2 \
         GROUP BY m.conversation_id \
         ORDER BY MAX(m.created_at) DESC \
         LIMIT $3"
    )
    .bind(user_id).bind(&pattern).bind(limit)
    .fetch_all(service.db())
    .await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let mut result = Vec::new();
    for (conv_id, match_count) in groups {
        // 会话信息
        let conv_info: Option<(Option<String>, Option<String>, i16)> = sqlx::query_as(
            "SELECT c.name, c.avatar, c.type FROM conversations c WHERE c.id = $1"
        ).bind(conv_id).fetch_optional(service.db()).await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        let (conv_name_raw, conv_avatar_raw, conv_type) = conv_info.unwrap_or((None, None, 0));

        // 单聊：取对方昵称和头像
        let (conversation_name, conversation_avatar) = if conv_type == 0 {
            let peer: Option<(String, Option<String>)> = sqlx::query_as(
                "SELECT COALESCE(up.nickname, '?'), up.avatar \
                 FROM conversation_members cm \
                 LEFT JOIN user_profiles up ON up.account_id = cm.user_id \
                 WHERE cm.conversation_id = $1 AND cm.user_id != $2 AND cm.is_deleted = false \
                 LIMIT 1"
            ).bind(conv_id).bind(user_id).fetch_optional(service.db()).await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
            peer.unwrap_or(("?".to_string(), None))
        } else {
            (conv_name_raw.unwrap_or("?".to_string()), conv_avatar_raw)
        };

        // 最近 3 条匹配消息
        let messages: Vec<(Uuid, String, Option<String>, String, chrono::DateTime<chrono::Utc>)> = sqlx::query_as(
            "SELECT m.id, COALESCE(up.nickname, '?'), up.avatar, m.content, m.created_at \
             FROM messages m \
             LEFT JOIN user_profiles up ON up.account_id = m.sender_id \
             WHERE m.conversation_id = $1 AND m.type = 0 AND m.content ILIKE $2 \
             ORDER BY m.created_at DESC \
             LIMIT 3"
        ).bind(conv_id).bind(&pattern).fetch_all(service.db()).await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        let msg_list: Vec<serde_json::Value> = messages.into_iter().map(|(id, name, avatar, content, created_at)| {
            serde_json::json!({
                "message_id": id.to_string(),
                "sender_name": name,
                "sender_avatar": avatar,
                "content": content,
                "created_at": created_at.to_rfc3339(),
            })
        }).collect();

        result.push(serde_json::json!({
            "conversation_id": conv_id.to_string(),
            "conversation_name": conversation_name,
            "conversation_avatar": conversation_avatar,
            "conv_type": conv_type,
            "match_count": match_count,
            "messages": msg_list,
        }));
    }

    Ok(Json(serde_json::json!({ "data": result })))
}
```

### 3.3 注册路由 `⬜`

```rust
.route("/api/messages/search", get(search_messages))
```

---

## 任务 4：GET /conversations/{id}/messages/search `⬜ 待处理`

文件：`server/modules/im-message/src/routes.rs`（修改）

### 4.1 新增 handler `⬜`

```rust
/// GET /conversations/{conv_id}/messages/search — 会话内消息搜索
async fn search_conversation_messages(
    State(service): State<Arc<MessageService>>,
    headers: HeaderMap,
    Path(conv_id_str): Path<String>,
    Query(params): Query<HashMap<String, String>>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let _user_id = extract_user_id(&headers)?;
    let conv_id = Uuid::parse_str(&conv_id_str).map_err(|_| StatusCode::BAD_REQUEST)?;
    let keyword = params.get("keyword").cloned().unwrap_or_default();
    let limit: i32 = params.get("limit").and_then(|v| v.parse().ok()).unwrap_or(20).min(100).max(1);
    let offset: i32 = params.get("offset").and_then(|v| v.parse().ok()).unwrap_or(0).max(0);

    let escaped = keyword.replace('%', "\\%").replace('_', "\\_");
    let pattern = format!("%{}%", escaped);

    let rows: Vec<(Uuid, String, Option<String>, String, i64, chrono::DateTime<chrono::Utc>)> = sqlx::query_as(
        "SELECT m.id, COALESCE(up.nickname, '?'), up.avatar, m.content, m.seq, m.created_at \
         FROM messages m \
         LEFT JOIN user_profiles up ON up.account_id = m.sender_id \
         WHERE m.conversation_id = $1 AND m.type = 0 AND m.content ILIKE $2 \
         ORDER BY m.created_at DESC \
         LIMIT $3 OFFSET $4"
    )
    .bind(conv_id).bind(&pattern).bind(limit).bind(offset)
    .fetch_all(service.db())
    .await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let data: Vec<serde_json::Value> = rows.into_iter().map(|(id, name, avatar, content, seq, created_at)| {
        serde_json::json!({
            "message_id": id.to_string(),
            "sender_name": name,
            "sender_avatar": avatar,
            "content": content,
            "seq": seq,
            "created_at": created_at.to_rfc3339(),
        })
    }).collect();

    Ok(Json(serde_json::json!({ "data": data })))
}
```

### 4.2 注册路由 `⬜`

```rust
.route("/conversations/{conv_id}/messages/search", get(search_conversation_messages))
```

---

## 任务 5：编译验证 `⬜ 待处理`

### 5.1 编译 `⬜`

```bash
cargo build
```

### 5.2 手动测试路径 `⬜`

1. GET /api/friends/search?keyword=橘 → 返回好友列表
2. GET /api/conversations/search-joined-groups?keyword=技术 → 返回已加入的群
3. GET /api/messages/search?keyword=你好 → 返回按会话分组的消息
4. GET /conversations/{id}/messages/search?keyword=你好 → 返回单会话消息
5. 搜索 `%` → 不报错，返回空或正确结果
