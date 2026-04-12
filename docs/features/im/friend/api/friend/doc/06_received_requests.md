# GET /api/friends/requests/received

查询收到的好友申请列表（仅 pending 状态）。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| limit | int | 否 | 每页条数，默认 20 |
| offset | int | 否 | 偏移量，默认 0 |

## Response `200`

```json
{"data":[{"avatar":"identicon:朱红:ed5126","created_at":"2026-04-12T10:19:31.203326Z","from_user_id":"1","id":"2b341702-4c15-4a4d-b01a-d0b02a868b23","message":"再发一次","nickname":"朱红","status":0,"to_user_id":"2","updated_at":"2026-04-12T10:19:31.231287Z"}]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/friends/requests/received"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc2NTkzOTcxLCJpYXQiOjE3NzU5ODkxNzF9.uTKpnAs-iQXqTwHrUv3vxuifdbjtQNXG_K04CIgMuNg"
```