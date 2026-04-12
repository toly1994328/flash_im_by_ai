# POST /api/friends/requests/2b341702-4c15-4a4d-b01a-d0b02a868b23/accept

重复接受已处理的申请。

## Response `403`

```json
{"error":"无权操作"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/friends/requests/2b341702-4c15-4a4d-b01a-d0b02a868b23/accept"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc2NTkzOTcxLCJpYXQiOjE3NzU5ODkxNzF9.uTKpnAs-iQXqTwHrUv3vxuifdbjtQNXG_K04CIgMuNg"
```

> 申请已非 pending 状态时返回 403。