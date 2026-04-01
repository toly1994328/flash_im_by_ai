# GET /conversations

对方仍能看到被删除的会话。

## Response `200`

```json
[{"avatar":"identicon:1:ed5126","conv_type":0,"created_at":"2026-03-29T02:59:10.424344Z","id":"d1752cc9-8a9c-428c-b97b-f030655c7afb","is_muted":false,"is_pinned":false,"last_message_at":null,"last_message_preview":null,"name":"朱红","peer_avatar":"identicon:1:ed5126","peer_nickname":"朱红","peer_user_id":"1","unread_count":0}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc1NDA1OTIyLCJpYXQiOjE3NzQ4MDExMjJ9.Lk0wGV5Pnhy_2hbuoLQYNZ-WPc4FCYZL-km2Qxh-xFk"
```

> 软删除仅影响操作者，对方不受影响。