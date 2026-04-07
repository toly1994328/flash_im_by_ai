# GET /api/friends/requests/received

拒绝后查询收到的申请，被拒绝的不再显示（仅返回 pending）。

## Response `200`

```json
{"data":[]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/friends/requests/received"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc2MTI3MjQ4LCJpYXQiOjE3NzU1MjI0NDh9.nkv_NMiXfF_Qy_C3J5nM2zbXlGGMWNO7_DQFEz89Z24"
```