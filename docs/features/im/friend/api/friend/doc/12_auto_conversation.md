# GET /conversations

验证接受好友后自动创建的私聊会话。

## Response `200`

```json
[{"avatar":"identicon:2","conv_type":0,"created_at":"2026-04-07T00:40:48.651644Z","id":"3f6d3ab1-dca9-4dbd-a10f-c66d46291087","is_muted":false,"is_pinned":false,"last_message_at":"2026-04-07T00:40:48.660195Z","last_message_preview":"你好，我是测试用户A","name":"用户0002","peer_avatar":"identicon:2","peer_nickname":"用户0002","peer_user_id":"2","unread_count":0}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2MTI3MjQ4LCJpYXQiOjE3NzU1MjI0NDh9.NOjzp1Fxet0WEQpJBHyW3lhFZ89dSQ0W4oPEsJzJfv4"
```

> 接受好友申请后，系统自动创建私聊会话并发送打招呼消息。