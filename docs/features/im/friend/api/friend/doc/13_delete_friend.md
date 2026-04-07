# DELETE /api/friends/2

删除好友，双向关系同时解除。

## Response `200`

```json
{"data":null}
```

## curl

```bash
curl -s -X DELETE "http://127.0.0.1:9600/api/friends/2"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2MTI3MjQ4LCJpYXQiOjE3NzU1MjI0NDh9.NOjzp1Fxet0WEQpJBHyW3lhFZ89dSQ0W4oPEsJzJfv4"
```

> 删除后双方的好友列表中都不再包含对方。WS 通知双方。