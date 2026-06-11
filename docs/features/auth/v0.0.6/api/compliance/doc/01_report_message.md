# POST /api/reports

举报消息或用户。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| target_type | int | 是 | 0=消息, 1=用户 |
| target_id | string | 是 | 消息ID 或 用户ID |
| reason | int | 是 | 0=色情, 1=暴力, 2=骚扰, 3=诈骗, 4=其他 |
| description | string | 否 | 补充说明 |

```json
{"target_type": 0, "target_id": "fake-msg-id-123", "reason": 2, "description": "test harassment"}
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
  -d '{"target_type": 0, "target_id": "fake-msg-id-123", "reason": 2, "description": "test harassment"}'
```