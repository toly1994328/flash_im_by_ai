# POST /conversations

创建会话时对方用户不存在。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| peer_user_id | int | 是 | 对方用户 ID（不存在） |

```json
{"peer_user_id": 999999}
```

## Response `404`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/conversations"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc1NDA1OTIyLCJpYXQiOjE3NzQ4MDExMjJ9.giI1rG-7ytHzmEykcXLygkv98s60ITQA3fVgBRiH8gY"
  -H "Content-Type: application/json"
  -d '{"peer_user_id": 999999}'
```

> peer_user_id 不存在时返回 404。