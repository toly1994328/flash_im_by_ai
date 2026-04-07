# POST /api/friends/requests/47932555-560d-45d0-9c83-06681781cde6/accept

重复接受已处理的申请。

## Response `403`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/friends/requests/47932555-560d-45d0-9c83-06681781cde6/accept"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc2MTI3MjQ4LCJpYXQiOjE3NzU1MjI0NDh9.nkv_NMiXfF_Qy_C3J5nM2zbXlGGMWNO7_DQFEz89Z24"
```

> 申请已非 pending 状态时返回 403。