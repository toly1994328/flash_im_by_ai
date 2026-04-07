# GET /api/friends

删除好友后查询列表，已删除的好友不再出现。

## Response `200`

```json
{"data":[]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/friends"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2MTI3MjQ4LCJpYXQiOjE3NzU1MjI0NDh9.NOjzp1Fxet0WEQpJBHyW3lhFZ89dSQ0W4oPEsJzJfv4"
```