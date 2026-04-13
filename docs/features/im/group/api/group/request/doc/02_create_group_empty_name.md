# POST /conversations

群名为空时返回 400。

```json
{"type": "group", "name": "", "member_ids": [2, 3]}
```

## Response `400`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/conversations"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.e2lTgvQvUYvq00t9MNlOiNh1Pc66a5qoJGf-fx_5rws"
  -H "Content-Type: application/json"
  -d '{"type": "group", "name": "", "member_ids": [2, 3]}'
```

> 群名 trim 后为空即拒绝。