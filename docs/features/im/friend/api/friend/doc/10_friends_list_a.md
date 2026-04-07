# GET /api/friends

查询好友列表（A 视角），接受申请后 B 应出现在列表中。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| limit | int | 否 | 每页条数，默认 20 |
| offset | int | 否 | 偏移量，默认 0 |

## Response `200`

```json
{"data":[{"avatar":"identicon:2","bio":null,"created_at":"2026-04-07T00:40:48.646451Z","friend_id":"2","nickname":"用户0002"}]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/friends"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2MTI3MjQ4LCJpYXQiOjE3NzU1MjI0NDh9.NOjzp1Fxet0WEQpJBHyW3lhFZ89dSQ0W4oPEsJzJfv4"
```