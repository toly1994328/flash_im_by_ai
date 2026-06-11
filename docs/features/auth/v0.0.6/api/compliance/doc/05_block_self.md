# POST /api/blocks

不能拉黑自己。

```json
{"blocked_id": 2}
```

## Response `400`

```json
{"error":"不能拉黑自己","status":400}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/blocks"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgxNzM5MjA4LCJpYXQiOjE3ODExMzQ0MDh9.EMBPh2qwXnrst4SJ4KfJqmrnmTVI6_f7xTosC3742NE"
  -H "Content-Type: application/json"
  -d '{"blocked_id": 2}'
```

> 错误场景：blocker_id == blocked_id