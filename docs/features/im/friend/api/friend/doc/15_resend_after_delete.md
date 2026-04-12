# POST /api/friends/requests

删除好友后可以重新发送申请。

```json
{"to_user_id": 2, "message": "\u518d\u6b21\u6dfb\u52a0"}
```

## Response `200`

```json
{"data":{"created_at":"2026-04-12T10:19:31.203326Z","from_user_id":"1","id":"2b341702-4c15-4a4d-b01a-d0b02a868b23","message":"再次添加","status":0,"to_user_id":"2","updated_at":"2026-04-12T10:19:31.604961Z"}}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/friends/requests"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NTkzOTcxLCJpYXQiOjE3NzU5ODkxNzF9.zS0yoOjS3x0n-SO_8A6zqWxQ3MVfFKqmBR3Gzav0T5Q"
  -H "Content-Type: application/json"
  -d '{"to_user_id": 2, "message": "\u518d\u6b21\u6dfb\u52a0"}'
```

> 删除好友后，UNIQUE 约束通过 ON CONFLICT DO UPDATE 重置申请状态。