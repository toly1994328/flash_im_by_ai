# POST /api/friends/requests

发送好友申请，可附带留言。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| to_user_id | int | 是 | 目标用户 ID |
| message | string | 否 | 申请留言，最长 200 字 |

```json
{"to_user_id": 2, "message": "\u4f60\u597d\uff0c\u6211\u662f\u6d4b\u8bd5\u7528\u6237A"}
```

## Response `200`

```json
{"data":{"created_at":"2026-04-12T10:19:31.203326Z","from_user_id":"1","id":"2b341702-4c15-4a4d-b01a-d0b02a868b23","message":"你好，我是测试用户A","status":0,"to_user_id":"2","updated_at":"2026-04-12T10:19:31.203326Z"}}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/friends/requests"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NTkzOTcxLCJpYXQiOjE3NzU5ODkxNzF9.zS0yoOjS3x0n-SO_8A6zqWxQ3MVfFKqmBR3Gzav0T5Q"
  -H "Content-Type: application/json"
  -d '{"to_user_id": 2, "message": "\u4f60\u597d\uff0c\u6211\u662f\u6d4b\u8bd5\u7528\u6237A"}'
```