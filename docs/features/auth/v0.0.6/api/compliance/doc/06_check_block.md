# GET /api/blocks/check?user_id=3

检查是否已拉黑某用户。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| user_id | int | 是 | 待检查的用户 ID (query param) |

## Response `200`

```json
{"is_blocked":true}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/blocks/check?user_id=3"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgxNzM5MjA4LCJpYXQiOjE3ODExMzQ0MDh9.EMBPh2qwXnrst4SJ4KfJqmrnmTVI6_f7xTosC3742NE"
```