# GET /api/friends/requests/received

查询收到的好友申请列表（仅 pending 状态）。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| limit | int | 否 | 每页条数，默认 20 |
| offset | int | 否 | 偏移量，默认 0 |

## Response `200`

```json
{"data":[{"avatar":"identicon:1","created_at":"2026-04-07T00:40:48.428204Z","from_user_id":"1","id":"47932555-560d-45d0-9c83-06681781cde6","message":"你好，我是测试用户A","nickname":"用户0001","status":0,"to_user_id":"2","updated_at":"2026-04-07T00:40:48.428204Z"}]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/friends/requests/received"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc2MTI3MjQ4LCJpYXQiOjE3NzU1MjI0NDh9.nkv_NMiXfF_Qy_C3J5nM2zbXlGGMWNO7_DQFEz89Z24"
```