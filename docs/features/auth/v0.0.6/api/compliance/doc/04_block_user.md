# POST /api/blocks

拉黑用户。同时解除好友关系。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| blocked_id | int | 是 | 被拉黑的用户 ID |

```json
{"blocked_id": 3}
```

## Response `201`

```json
{"message":"已拉黑"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/blocks"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgxNzM5MjA4LCJpYXQiOjE3ODExMzQ0MDh9.EMBPh2qwXnrst4SJ4KfJqmrnmTVI6_f7xTosC3742NE"
  -H "Content-Type: application/json"
  -d '{"blocked_id": 3}'
```