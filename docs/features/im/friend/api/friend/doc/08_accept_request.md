# POST /api/friends/requests/2b341702-4c15-4a4d-b01a-d0b02a868b23/accept

接受好友申请。副作用：创建双向好友关系 + 自动创建私聊会话 + 发送打招呼消息。

## Response `200`

```json
{"data":null}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/friends/requests/2b341702-4c15-4a4d-b01a-d0b02a868b23/accept"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc2NTkzOTcxLCJpYXQiOjE3NzU5ODkxNzF9.uTKpnAs-iQXqTwHrUv3vxuifdbjtQNXG_K04CIgMuNg"
```

> 只有被申请者（to_user_id）可以接受。接受后自动创建私聊会话并发送打招呼消息。