# POST /api/friends/requests/2b341702-4c15-4a4d-b01a-d0b02a868b23/reject

拒绝好友申请。

## Response `200`

```json
{"data":null}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/friends/requests/2b341702-4c15-4a4d-b01a-d0b02a868b23/reject"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc2NTkzOTcxLCJpYXQiOjE3NzU5ODkxNzF9.uTKpnAs-iQXqTwHrUv3vxuifdbjtQNXG_K04CIgMuNg"
```

> 拒绝后申请状态变为 rejected，不通知申请者。