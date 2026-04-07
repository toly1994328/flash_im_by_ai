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
{"data":{"created_at":"2026-04-07T00:40:48.428204Z","from_user_id":"1","id":"47932555-560d-45d0-9c83-06681781cde6","message":"你好，我是测试用户A","status":0,"to_user_id":"2","updated_at":"2026-04-07T00:40:48.428204Z"}}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/friends/requests"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2MTI3MjQ4LCJpYXQiOjE3NzU1MjI0NDh9.NOjzp1Fxet0WEQpJBHyW3lhFZ89dSQ0W4oPEsJzJfv4"
  -H "Content-Type: application/json"
  -d '{"to_user_id": 2, "message": "\u4f60\u597d\uff0c\u6211\u662f\u6d4b\u8bd5\u7528\u6237A"}'
```