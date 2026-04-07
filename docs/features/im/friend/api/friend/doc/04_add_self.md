# POST /api/friends/requests

不能添加自己为好友。

```json
{"to_user_id": 1}
```

## Response `400`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/friends/requests"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2MTI3MjQ4LCJpYXQiOjE3NzU1MjI0NDh9.NOjzp1Fxet0WEQpJBHyW3lhFZ89dSQ0W4oPEsJzJfv4"
  -H "Content-Type: application/json"
  -d '{"to_user_id": 1}'
```

> to_user_id 等于自己时返回 400。