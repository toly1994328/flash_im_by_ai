# POST /conversations

单聊创建走独立的 POST /conversations，不受群聊影响。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| peer_user_id | int | 是 | 对方用户 ID |

```json
{"peer_user_id": 4}
```

## Response `200`

```json
{"avatar":"identicon:碧螺春绿:867018","conv_type":0,"created_at":"2026-04-15T23:24:20.672615Z","id":"6f5183a4-af38-4fc5-9256-d7df47051131","name":"碧螺春绿","owner_id":null,"peer_avatar":"identicon:碧螺春绿:867018","peer_nickname":"碧螺春绿","peer_user_id":"4"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/conversations"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MDUxMzA2LCJpYXQiOjE3NzY0NDY1MDZ9.RnddDHuGfJO_OhSBvfI0r626elwvlXOR-DZWQhRlKrA"
  -H "Content-Type: application/json"
  -d '{"peer_user_id": 4}'
```