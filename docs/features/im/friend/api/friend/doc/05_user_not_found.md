# POST /api/friends/requests

目标用户不存在。

```json
{"to_user_id": 999999}
```

## Response `404`

```json
{"error":"用户不存在"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/friends/requests"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NTkzOTcxLCJpYXQiOjE3NzU5ODkxNzF9.zS0yoOjS3x0n-SO_8A6zqWxQ3MVfFKqmBR3Gzav0T5Q"
  -H "Content-Type: application/json"
  -d '{"to_user_id": 999999}'
```

> to_user_id 不存在时返回 404。