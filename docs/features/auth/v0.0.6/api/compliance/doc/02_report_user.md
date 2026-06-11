# POST /api/reports

举报用户（reason=3 诈骗）。

```json
{"target_type": 1, "target_id": "3", "reason": 3}
```

## Response `201`

```json
{"message":"举报已提交"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/reports"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgxNzM5MjA4LCJpYXQiOjE3ODExMzQ0MDh9.EMBPh2qwXnrst4SJ4KfJqmrnmTVI6_f7xTosC3742NE"
  -H "Content-Type: application/json"
  -d '{"target_type": 1, "target_id": "3", "reason": 3}'
```