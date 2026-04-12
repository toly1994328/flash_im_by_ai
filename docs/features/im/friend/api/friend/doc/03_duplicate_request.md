# POST /api/friends/requests

重复发送好友申请（upsert 覆盖旧申请，更新留言）。

```json
{"to_user_id": 2, "message": "\u518d\u53d1\u4e00\u6b21"}
```

## Response `200`

```json
{"data":{"created_at":"2026-04-12T10:19:31.203326Z","from_user_id":"1","id":"2b341702-4c15-4a4d-b01a-d0b02a868b23","message":"再发一次","status":0,"to_user_id":"2","updated_at":"2026-04-12T10:19:31.231287Z"}}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/friends/requests"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NTkzOTcxLCJpYXQiOjE3NzU5ODkxNzF9.zS0yoOjS3x0n-SO_8A6zqWxQ3MVfFKqmBR3Gzav0T5Q"
  -H "Content-Type: application/json"
  -d '{"to_user_id": 2, "message": "\u518d\u53d1\u4e00\u6b21"}'
```

> 同一对用户重复发送时，覆盖旧申请的留言和状态，返回 200。