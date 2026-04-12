# GET /api/friends

查询好友列表（B 视角），双向关系验证。

## Response `200`

```json
{"data":[{"avatar":"identicon:朱红:ed5126","bio":null,"created_at":"2026-04-12T10:19:31.398854Z","friend_id":"1","nickname":"朱红"}]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/friends"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc2NTkzOTcxLCJpYXQiOjE3NzU5ODkxNzF9.uTKpnAs-iQXqTwHrUv3vxuifdbjtQNXG_K04CIgMuNg"
```