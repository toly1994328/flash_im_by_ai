# 综合搜索 — 后端局域网络

涉及节点：D-35 ~ D-38

---

## 一、远景：模块与依赖

### 涉及模块

| 模块 | 位置 | 职责 |
|------|------|------|
| im-friend | server/modules/im-friend/ | 好友搜索接口 |
| im-conversation | server/modules/im-conversation/ | 已加入群搜索接口 |
| im-message | server/modules/im-message/ | 消息搜索接口（跨会话 + 会话内） |

### 节点详情

| 编号 | 功能节点 | 模块 | 职责 |
|------|---------|------|------|
| D-35 | 好友搜索 | im-friend/api | GET /api/friends/search，按昵称 ILIKE 匹配当前用户的好友 |
| D-36 | 已加入群搜索 | im-conversation/routes | GET /api/conversations/search-joined-groups，按群名 ILIKE 匹配已加入且未解散的群 |
| D-37 | 消息搜索 | im-message/routes | GET /api/messages/search，跨会话搜索文本消息，按会话分组返回 |
| D-38 | 会话内消息搜索 | im-message/routes | GET /conversations/{id}/messages/search，单会话内搜索，支持 offset 分页 |

---

## 二、中景：数据通道与事件流

### 边界接口

**HTTP 接口**

| 接口 | 提供节点 | 消费节点 |
|------|---------|---------|
| GET /api/friends/search | D-35 | F-14 → P-44 |
| GET /api/conversations/search-joined-groups | D-36 | F-14 → P-44 |
| GET /api/messages/search | D-37 | F-14 → P-44 |
| GET /conversations/{id}/messages/search | D-38 | F-14 → P-46 |

---

## 四、版本演进

| 版本 | 变更 |
|------|------|
| v0.0.1_search | 初始实现：好友搜索、已加入群搜索、消息搜索（按会话分组）、会话内消息搜索（offset 分页） |
