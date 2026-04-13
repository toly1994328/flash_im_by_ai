# POST /conversations

单聊创建不受群聊扩展影响。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| type | string | 否 | "private"（默认值） |
| peer_user_id | int | 是 | 对方用户 ID |

```json
{"type": "private", "peer_user_id": 5}
```

## Response `200`

```json
{"avatar":"identicon:5","conv_type":0,"created_at":"2026-04-12T14:40:38.053508Z","id":"5f98c0c5-2b1d-4ae8-9adb-af1d2f303e12","name":"用户0005","owner_id":null,"peer_avatar":"identicon:5","peer_nickname":"用户0005","peer_user_id":"5"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/conversations"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.e2lTgvQvUYvq00t9MNlOiNh1Pc66a5qoJGf-fx_5rws"
  -H "Content-Type: application/json"
  -d '{"type": "private", "peer_user_id": 5}'
```