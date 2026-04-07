# GET /api/friends

查询好友列表（B 视角），双向关系验证。

## Response `200`

```json
{"data":[{"avatar":"identicon:1","bio":null,"created_at":"2026-04-07T00:40:48.646451Z","friend_id":"1","nickname":"用户0001"}]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/friends"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc2MTI3MjQ4LCJpYXQiOjE3NzU1MjI0NDh9.nkv_NMiXfF_Qy_C3J5nM2zbXlGGMWNO7_DQFEz89Z24"
```