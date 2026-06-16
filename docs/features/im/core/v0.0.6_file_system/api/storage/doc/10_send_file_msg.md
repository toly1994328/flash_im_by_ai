# POST /conversations/5cf31a40-473d-4aa9-8208-320e29f98b5b/messages

发送文件消息。content=文件 URL，extra 含文件名/大小/类型，msg_type=3（FILE）。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| content | string | 是 | 文件 URL |
| msg_type | int | 是 | 3=FILE |
| extra | json | 是 | 文件元数据 |

## Response `200`

```json
{"content":"/uploads/file/2026/06/f36a72ae-8b19-4192-bd18-0b0ec6940e88.txt","conversation_id":"5cf31a40-473d-4aa9-8208-320e29f98b5b","created_at":"2026-06-16T21:59:45.762504Z","extra":{"file_name":"test.txt","file_size":190,"file_type":"txt","file_url":"/uploads/file/2026/06/f36a72ae-8b19-4192-bd18-0b0ec6940e88.txt"},"id":"ab748e90-c2d4-4acd-9f65-289ddf99dfac","msg_type":3,"sender_id":2,"seq":7,"status":0}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/conversations/5cf31a40-473d-4aa9-8208-320e29f98b5b/messages"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyMjUxOTg1LCJpYXQiOjE3ODE2NDcxODV9.rCbkWzYq8CjyLgp2MfgnxoG41jerLuK5X1RFUhJsWtg"
```