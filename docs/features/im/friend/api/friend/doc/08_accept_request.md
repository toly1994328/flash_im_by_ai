# POST /api/friends/requests/47932555-560d-45d0-9c83-06681781cde6/accept

接受好友申请。副作用：创建双向好友关系 + 自动创建私聊会话 + 发送打招呼消息。

## Response `200`

```json
{"data":null}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/friends/requests/47932555-560d-45d0-9c83-06681781cde6/accept"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc2MTI3MjQ4LCJpYXQiOjE3NzU1MjI0NDh9.nkv_NMiXfF_Qy_C3J5nM2zbXlGGMWNO7_DQFEz89Z24"
```

> 只有被申请者（to_user_id）可以接受。接受后自动创建私聊会话并发送打招呼消息。