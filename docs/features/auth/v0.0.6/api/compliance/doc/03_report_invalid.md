# POST /api/reports

举报参数错误（reason 无效）。

```json
{"target_type": 0, "target_id": "abc", "reason": 99}
```

## Response `400`

```json
{"error":"reason 无效","status":400}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/reports"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgxNzM5MjA4LCJpYXQiOjE3ODExMzQ0MDh9.EMBPh2qwXnrst4SJ4KfJqmrnmTVI6_f7xTosC3742NE"
  -H "Content-Type: application/json"
  -d '{"target_type": 0, "target_id": "abc", "reason": 99}'
```

> 错误场景：reason 超出 0~4 范围