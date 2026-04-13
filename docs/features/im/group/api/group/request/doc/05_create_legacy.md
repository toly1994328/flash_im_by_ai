# POST /conversations

旧格式兼容：不传 type 字段时默认为 private。

```json
{"peer_user_id": 2}
```

## Response `200`

```json
{"avatar":"identicon:2","conv_type":0,"created_at":"2026-04-12T14:40:38.094159Z","id":"b5ffb276-bcd3-42c0-a5b4-8217e3f8b1d9","name":"用户0002","owner_id":null,"peer_avatar":"identicon:2","peer_nickname":"用户0002","peer_user_id":"2"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/conversations"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.e2lTgvQvUYvq00t9MNlOiNh1Pc66a5qoJGf-fx_5rws"
  -H "Content-Type: application/json"
  -d '{"peer_user_id": 2}'
```

> type 字段 serde default 为 "private"，兼容旧客户端。