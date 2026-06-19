# POST /conversations/5cf31a40-473d-4aa9-8208-320e29f98b5b/messages

发送图片消息。content=图片 URL，msg_type=1（IMAGE）。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| content | string | 是 | 图片 URL |
| msg_type | int | 是 | 1=IMAGE |

## Response `200`

```json
{"content":"/uploads/original/2026/06/cf8c75aa-cd6c-48e3-a144-653ab55a1940.png","conversation_id":"5cf31a40-473d-4aa9-8208-320e29f98b5b","created_at":"2026-06-16T21:59:45.586967Z","extra":null,"id":"8efae60f-a334-4d0f-9b2c-1fe12e6f071d","msg_type":1,"sender_id":2,"seq":5,"status":0}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/conversations/5cf31a40-473d-4aa9-8208-320e29f98b5b/messages"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyMjUxOTg1LCJpYXQiOjE3ODE2NDcxODV9.rCbkWzYq8CjyLgp2MfgnxoG41jerLuK5X1RFUhJsWtg"
```