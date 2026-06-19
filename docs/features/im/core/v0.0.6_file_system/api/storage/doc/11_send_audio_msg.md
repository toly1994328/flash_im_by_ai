# POST /conversations/5cf31a40-473d-4aa9-8208-320e29f98b5b/messages

发送语音消息。content=音频 URL，extra 含时长，msg_type=4（AUDIO）。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| content | string | 是 | 音频 URL |
| msg_type | int | 是 | 4=AUDIO |
| extra | json | 是 | 音频元数据 |

## Response `200`

```json
{"content":"/uploads/file/2026/06/42502df2-e174-45f8-9494-ec3491e02207.m4a","conversation_id":"5cf31a40-473d-4aa9-8208-320e29f98b5b","created_at":"2026-06-16T21:59:45.842648Z","extra":{"duration_ms":5200},"id":"93c156b0-8ab4-4e74-b6ca-0ef07cf17a5d","msg_type":4,"sender_id":2,"seq":8,"status":0}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/conversations/5cf31a40-473d-4aa9-8208-320e29f98b5b/messages"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyMjUxOTg1LCJpYXQiOjE3ODE2NDcxODV9.rCbkWzYq8CjyLgp2MfgnxoG41jerLuK5X1RFUhJsWtg"
```