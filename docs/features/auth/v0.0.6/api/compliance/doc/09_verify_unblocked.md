# GET /api/blocks/check?user_id=3

验证取消拉黑后 is_blocked=false。

## Response `200`

```json
{"is_blocked":false}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/blocks/check?user_id=3"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgxNzM5MjA4LCJpYXQiOjE3ODExMzQ0MDh9.EMBPh2qwXnrst4SJ4KfJqmrnmTVI6_f7xTosC3742NE"
```