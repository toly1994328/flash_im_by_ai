# POST /conversations

重复创建同一私聊，返回已有会话（幂等）。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| peer_user_id | int | 是 | 对方用户 ID |

```json
{"peer_user_id": 2}
```

## Response `200`

```json
{"conv_type":0,"created_at":"2026-03-29T02:59:10.424344Z","id":"d1752cc9-8a9c-428c-b97b-f030655c7afb","peer_avatar":"identicon:2:f97d1c","peer_nickname":"橘橙","peer_user_id":"2"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/conversations"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc1NDA1OTIyLCJpYXQiOjE3NzQ4MDExMjJ9.giI1rG-7ytHzmEykcXLygkv98s60ITQA3fVgBRiH8gY"
  -H "Content-Type: application/json"
  -d '{"peer_user_id": 2}'
```

> 返回相同的会话，不会重复创建。