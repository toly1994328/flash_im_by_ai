---
module: im-friend + im-conversation + im-message
version: v0.0.1_search
date: 2026-04-26
tags: [综合搜索, 好友搜索, 群搜索, 消息搜索]
---

# 综合搜索 — 服务端设计报告

> 关联设计：[功能分析](../analysis.md)

## 1. 目标

- 新增 GET /api/friends/search：搜索当前用户的好友（按昵称模糊匹配）
- 新增 GET /api/conversations/search-joined-groups：搜索当前用户已加入的群聊（按群名模糊匹配）
- 新增 GET /api/messages/search：跨会话搜索消息内容，按会话分组返回
- 新增 GET /conversations/{id}/messages/search：单会话内搜索消息内容

## 2. 现状分析

### 已有能力

- `GET /api/users/search`：搜索所有用户（按昵称/手机号/闪讯号），用于添加好友场景
- `GET /groups/search`：搜索所有群聊（按群名/群号），用于搜索加群场景
- `GET /api/friends`：获取好友列表（分页），无搜索过滤
- `GET /conversations`：获取会话列表（分页 + type 过滤），无关键词搜索

### 缺失

- 无好友搜索接口（只有全量用户搜索）
- 无已加入群搜索接口（只有全量群搜索）
- 无消息内容搜索接口
- 无会话内消息搜索接口

## 3. 数据模型

### 无新增表

所有搜索都是对已有表的查询：
- `friend_relations` + `user_profiles`：好友搜索
- `conversations` + `conversation_members`：已加入群搜索
- `messages` + `conversations` + `user_profiles`：消息搜索

### 设计决策

| 决策 | 理由 |
|------|------|
| 好友搜索独立于用户搜索 | 综合搜索只搜"我的好友"，不搜陌生人 |
| 已加入群搜索独立于群搜索 | 综合搜索只搜"我加入的群"，不搜公开群 |
| 消息搜索只搜文本消息 | msg_type = 0（文本），图片/视频/文件的 content 是 URL，搜索无意义 |
| 消息搜索过滤系统消息 | sender_id != 0，系统消息（创建群聊等）搜索无意义 |
| 消息搜索按会话分组 | 返回 List<MessageSearchGroup>，每组含会话信息 + 匹配消息 + 匹配总数 |
| 会话内搜索独立接口 | 综合搜索跨会话（按会话分组），会话内搜索单会话（直接返回消息列表） |
| 搜索用 ILIKE | PostgreSQL 原生支持，不引入全文搜索引擎 |

## 4. 新增 HTTP 接口

### GET /api/friends/search

搜索当前用户的好友，按昵称模糊匹配。

请求参数：
- `keyword`（必填）：搜索关键词
- `limit`（可选，默认 20）：返回数量上限

SQL：
```sql
SELECT fr.friend_id, COALESCE(up.nickname, '?') AS nickname, up.avatar
FROM friend_relations fr
LEFT JOIN user_profiles up ON up.account_id = fr.friend_id
WHERE fr.user_id = $1 AND up.nickname ILIKE $2
ORDER BY up.nickname
LIMIT $3
```

成功响应 200：
```json
{
  "data": [
    { "friend_id": "2", "nickname": "橘橙", "avatar": "identicon:橘橙:f97d1c" }
  ]
}
```

### GET /api/conversations/search-joined-groups

搜索当前用户已加入的群聊，按群名模糊匹配。

请求参数：
- `keyword`（必填）：搜索关键词
- `limit`（可选，默认 20）：返回数量上限

SQL：
```sql
SELECT c.id AS conversation_id, c.name, c.avatar,
    (SELECT COUNT(*) FROM conversation_members WHERE conversation_id = c.id AND is_deleted = false) AS member_count
FROM conversations c
INNER JOIN conversation_members cm ON cm.conversation_id = c.id AND cm.user_id = $1 AND cm.is_deleted = false
WHERE c.type = 1 AND COALESCE(c.status, 0::SMALLINT) = 0 AND c.name ILIKE $2
ORDER BY c.name
LIMIT $3
```

成功响应 200：
```json
{
  "data": [
    { "conversation_id": "uuid", "name": "技术交流群", "avatar": "grid:...", "member_count": 5 }
  ]
}
```

### GET /api/messages/search

跨会话搜索消息内容，按会话分组返回。只搜文本消息（msg_type = 0）。

请求参数：
- `keyword`（必填）：搜索关键词
- `limit`（可选，默认 10）：返回的会话分组数量上限

SQL 分两步：

第一步：找到匹配的会话及匹配数
```sql
SELECT m.conversation_id, COUNT(*) AS match_count
FROM messages m
INNER JOIN conversation_members cm ON cm.conversation_id = m.conversation_id AND cm.user_id = $1 AND cm.is_deleted = false
WHERE m.type = 0 AND m.content ILIKE $2
GROUP BY m.conversation_id
ORDER BY MAX(m.created_at) DESC
LIMIT $3
```

第二步：对每个会话取最近 3 条匹配消息 + 会话信息
```sql
SELECT m.id AS message_id, m.content, m.created_at,
    COALESCE(up.nickname, '?') AS sender_name, up.avatar AS sender_avatar
FROM messages m
LEFT JOIN user_profiles up ON up.account_id = m.sender_id
WHERE m.conversation_id = $1 AND m.type = 0 AND m.content ILIKE $2
ORDER BY m.created_at DESC
LIMIT 3
```

会话信息：
```sql
SELECT c.id, c.name, c.avatar, c.type,
    CASE WHEN c.type = 0 THEN
        (SELECT COALESCE(up.nickname, '?') FROM conversation_members cm2
         LEFT JOIN user_profiles up ON up.account_id = cm2.user_id
         WHERE cm2.conversation_id = c.id AND cm2.user_id != $1 AND cm2.is_deleted = false LIMIT 1)
    ELSE c.name END AS conversation_name,
    CASE WHEN c.type = 0 THEN
        (SELECT up.avatar FROM conversation_members cm2
         LEFT JOIN user_profiles up ON up.account_id = cm2.user_id
         WHERE cm2.conversation_id = c.id AND cm2.user_id != $1 AND cm2.is_deleted = false LIMIT 1)
    ELSE c.avatar END AS conversation_avatar
FROM conversations c WHERE c.id = $1
```

成功响应 200：
```json
{
  "data": [
    {
      "conversation_id": "uuid",
      "conversation_name": "橘橙",
      "conversation_avatar": "identicon:...",
      "conv_type": 0,
      "match_count": 5,
      "messages": [
        { "message_id": "uuid", "sender_name": "橘橙", "sender_avatar": "...", "content": "...", "created_at": "..." }
      ]
    }
  ]
}
```

### GET /conversations/{id}/messages/search

单会话内搜索消息内容。只搜文本消息。

请求参数：
- `keyword`（必填）：搜索关键词
- `limit`（可选，默认 20）：返回数量上限
- `offset`（可选，默认 0）：分页偏移量

SQL：
```sql
SELECT m.id AS message_id, m.content, m.seq, m.created_at,
    COALESCE(up.nickname, '?') AS sender_name, up.avatar AS sender_avatar
FROM messages m
LEFT JOIN user_profiles up ON up.account_id = m.sender_id
WHERE m.conversation_id = $1 AND m.type = 0 AND m.sender_id != 0 AND m.content ILIKE $2
ORDER BY m.created_at DESC
LIMIT $3 OFFSET $4
```

成功响应 200：
```json
{
  "data": [
    { "message_id": "uuid", "sender_name": "橘橙", "sender_avatar": "...", "content": "...", "seq": 42, "created_at": "..." }
  ]
}
```

## 5. 项目结构与技术决策

### 变更范围

```
server/modules/
├── im-friend/src/
│   └── api.rs              # 新增：GET /api/friends/search
├── im-conversation/src/
│   └── routes.rs           # 新增：GET /api/conversations/search-joined-groups
├── im-message/src/
│   └── routes.rs           # 新增：GET /api/messages/search + GET /conversations/{id}/messages/search
```

### 技术决策

| 决策 | 方案 | 理由 |
|------|------|------|
| 搜索接口放在各自的 crate 中 | 好友搜索放 im-friend，群搜索放 im-conversation，消息搜索放 im-message | 不新建 crate，按数据归属分布 |
| 搜索用 ILIKE + 通配符转义 | `keyword.replace('%', "\\%").replace('_', "\\_")` + `format!("%{}%", keyword)` | 防止 SQL 注入，复用已有模式 |
| 消息搜索分两步查询 | 先查匹配的会话分组，再对每个会话取详情 | 避免一个巨大的 JOIN 查询，分步更可控 |
| 不引入全文搜索引擎 | 用 PostgreSQL ILIKE | 数据量小，ILIKE 够用，不增加基础设施复杂度 |

## 6. 验收标准

| 验收条件 | 验收方式 |
|----------|----------|
| 好友搜索：按昵称模糊匹配，只返回好友 | HTTP 请求 |
| 已加入群搜索：按群名模糊匹配，只返回已加入的群 | HTTP 请求 |
| 消息搜索：按内容模糊匹配，按会话分组返回 | HTTP 请求 |
| 消息搜索：只搜文本消息，不搜图片/视频/文件 | HTTP 请求 |
| 会话内搜索：只搜指定会话的消息 | HTTP 请求 |
| 关键词转义：搜索 `%` 或 `_` 不会导致异常 | HTTP 请求 |

## 7. 暂不实现

| 功能 | 理由 |
|------|------|
| 全文搜索（pg_trgm / tsvector） | 数据量小，ILIKE 够用 |
| 搜索结果分页 | 综合搜索每个分区最多返回 20 条，不需要分页 |
| 搜索结果排序权重 | 按时间倒序即可，不做相关性排序 |
