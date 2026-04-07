# POST /api/friends/requests/47932555-560d-45d0-9c83-06681781cde6/reject

拒绝好友申请。

## Response `200`

```json
{"data":null}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/friends/requests/47932555-560d-45d0-9c83-06681781cde6/reject"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc2MTI3MjQ4LCJpYXQiOjE3NzU1MjI0NDh9.nkv_NMiXfF_Qy_C3J5nM2zbXlGGMWNO7_DQFEz89Z24"
```

> 拒绝后申请状态变为 rejected，不通知申请者。