# POST /api/friends/requests

删除好友后可以重新发送申请。

```json
{"to_user_id": 2, "message": "\u518d\u6b21\u6dfb\u52a0"}
```

## Response `200`

```json
{"data":{"created_at":"2026-04-07T00:40:48.428204Z","from_user_id":"1","id":"47932555-560d-45d0-9c83-06681781cde6","message":"再次添加","status":0,"to_user_id":"2","updated_at":"2026-04-07T00:40:48.889367Z"}}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/friends/requests"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2MTI3MjQ4LCJpYXQiOjE3NzU1MjI0NDh9.NOjzp1Fxet0WEQpJBHyW3lhFZ89dSQ0W4oPEsJzJfv4"
  -H "Content-Type: application/json"
  -d '{"to_user_id": 2, "message": "\u518d\u6b21\u6dfb\u52a0"}'
```

> 删除好友后，UNIQUE 约束通过 ON CONFLICT DO UPDATE 重置申请状态。