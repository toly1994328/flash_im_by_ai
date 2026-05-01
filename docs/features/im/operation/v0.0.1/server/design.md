---
module: im-message + im-ws
version: v0.0.1_operation
date: 2026-05-01
tags: [消息撤回, MESSAGE_RECALLED, 引用回复]
---

# 消息操作 — 服务端设计报告

> 关联设计：[功能分析](../analysis.md)

## 1. 目标

- 新增消息撤回接口：POST /messages/{id}/recall
- 新增 MESSAGE_RECALLED WS 帧类型，撤回时广播给会话所有成员
- 引用回复不需要后端改动（复用 extra 字段）
- 复制、本地删除、多选是纯前端功能，后端不涉及

## 2. 现状分析

### 已有能力

- messages 表有 `status` 字段：0=正常，已有查询过滤 `status != 2`
- protobuf 已定义 `MessageStatus { NORMAL=0, RECALLED=1, DELETED=2 }`
- im-ws dispatcher 已有帧广播能力
- MessageService 已有 `broadcast_message` 方法

### 缺失

- 没有撤回接口
- proto 没有 MESSAGE_RECALLED 帧类型
- dispatcher 没有处理撤回帧的逻辑

## 3. 改动

### 3.1 proto 扩展

ws.proto 新增 MESSAGE_RECALLED 帧类型：

```protobuf
// ---> proto/ws.proto
enum WsFrameType {
  // ... 已有 0~15
  MESSAGE_RECALLED = 16;  // 新增
}
```

message.proto 新增 MessageRecalled 消息体：

```protobuf
// ---> proto/message.proto
message MessageRecalled {
  string message_id = 1;
  string conversation_id = 2;
  string sender_id = 3;       // 撤回者 ID
  string sender_name = 4;     // 撤回者昵称（前端展示用）
}
```

### 3.2 撤回接口

```
POST /conversations/{conv_id}/messages/{msg_id}/recall
Authorization: Bearer {token}
```

**校验逻辑**：

```python
# ---> server/modules/im-message/src/routes.rs（伪代码）
def recall_message(conv_id, msg_id, user_id):
    # 1. 查消息
    msg = SELECT * FROM messages WHERE id = msg_id AND conversation_id = conv_id
    if not msg: return 404

    # 2. 校验是否本人发送
    if msg.sender_id != user_id: return 403 "只能撤回自己的消息"

    # 3. 校验时间窗口（2 分钟）
    if now() - msg.created_at > 2 minutes: return 403 "超过撤回时限"

    # 4. 校验是否已撤回
    if msg.status == 1: return 400 "消息已撤回"

    # 5. 标记撤回
    UPDATE messages SET status = 1 WHERE id = msg_id

    # 6. 更新会话预览（如果撤回的是最后一条消息）
    update_conversation_preview(conv_id)

    # 7. 广播 MESSAGE_RECALLED 帧
    broadcast_recalled(conv_id, msg_id, user_id, sender_name)

    return 200
```

**响应**：

```json
// 成功
{ "message": "ok" }

// 失败
{ "error": "超过撤回时限" }  // 403
{ "error": "只能撤回自己的消息" }  // 403
{ "error": "消息已撤回" }  // 400
```

### 3.3 广播 MESSAGE_RECALLED 帧

撤回成功后，通过 broadcaster 向会话所有成员广播 MESSAGE_RECALLED 帧：

```python
# ---> server/modules/im-message/src/routes.rs（伪代码）
def broadcast_recalled(conv_id, msg_id, sender_id, sender_name):
    payload = MessageRecalled(
        message_id=msg_id,
        conversation_id=conv_id,
        sender_id=sender_id,
        sender_name=sender_name,
    )
    frame = WsFrame(type=MESSAGE_RECALLED, payload=payload)
    # 广播给会话所有成员（包括自己，前端根据 sender_id 判断展示文案）
    member_ids = SELECT user_id FROM conversation_members WHERE conversation_id = conv_id
    for uid in member_ids:
        ws_state.send(uid, frame)
```

### 3.4 会话预览更新

撤回消息后，如果撤回的是会话的最后一条消息，需要更新 `conversations.last_message_preview`：

```sql
-- 查询撤回后的最新消息预览
UPDATE conversations SET last_message_preview = (
    SELECT CASE WHEN m.status = 1 THEN '撤回了一条消息'
           ELSE CASE m.type WHEN 1 THEN '[图片]' WHEN 2 THEN '[视频]' WHEN 3 THEN '[文件]'
           ELSE SUBSTRING(m.content, 1, 50) END END
    FROM messages m WHERE m.conversation_id = $1
    ORDER BY m.seq DESC LIMIT 1
) WHERE id = $1
```

### 3.5 引用回复

引用回复不需要后端改动。前端发消息时在 extra 里携带 reply_to 信息：

```json
{
  "reply_to": {
    "message_id": "uuid",
    "sender_name": "朱红",
    "content": "明天几点开会？",
    "msg_type": 0
  }
}
```

后端照常存储 extra JSONB，不做特殊处理。

## 4. 设计决策

| 决策 | 方案 | 理由 |
|------|------|------|
| 撤回时间窗口 | 2 分钟 | 微信标准 |
| 撤回方式 | HTTP + WS 广播 | 撤回需要后端校验权限和时间，不能纯 WS |
| 撤回后 status | 1（RECALLED） | 复用已有 status 字段，不加新列 |
| 广播范围 | 会话所有成员（含自己） | 前端根据 sender_id 判断展示"你撤回"还是"对方撤回" |
| 引用回复 | extra 字段 | 复用已有 JSONB，不加新表 |
| 会话预览 | 撤回后更新 | 避免会话列表显示已撤回的消息内容 |

## 5. 验收标准

| 验收条件 | 验收方式 |
|----------|----------|
| 2 分钟内撤回成功 | HTTP 请求 |
| 超过 2 分钟撤回失败（403） | HTTP 请求 |
| 撤回别人的消息失败（403） | HTTP 请求 |
| 已撤回的消息再次撤回失败（400） | HTTP 请求 |
| 撤回后 WS 广播 MESSAGE_RECALLED 帧 | WS 监听 |
| 撤回后会话预览更新 | HTTP 查询会话 |
| 引用回复 extra 正确存储 | HTTP 查询消息 |
