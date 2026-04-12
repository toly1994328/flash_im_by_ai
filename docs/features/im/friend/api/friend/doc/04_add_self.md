# POST /api/friends/requests

不能添加自己为好友。

```json
{"to_user_id": 1}
```

## Response `400`

```json
{"error":"不能添加自己"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/friends/requests"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NTkzOTcxLCJpYXQiOjE3NzU5ODkxNzF9.zS0yoOjS3x0n-SO_8A6zqWxQ3MVfFKqmBR3Gzav0T5Q"
  -H "Content-Type: application/json"
  -d '{"to_user_id": 1}'
```

> to_user_id 等于自己时返回 400。