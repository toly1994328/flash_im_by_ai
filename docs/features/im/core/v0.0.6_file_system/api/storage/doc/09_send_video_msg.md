# POST /conversations/5cf31a40-473d-4aa9-8208-320e29f98b5b/messages

发送视频消息。content=视频 URL，extra 含缩略图/时长/宽高，msg_type=2（VIDEO）。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| content | string | 是 | 视频 URL |
| msg_type | int | 是 | 2=VIDEO |
| extra | json | 是 | 视频元数据 |

## Response `200`

```json
{"content":"/uploads/video/2026/06/8e57ff9b-1004-4282-95cd-014dc8ddab3f.mp4","conversation_id":"5cf31a40-473d-4aa9-8208-320e29f98b5b","created_at":"2026-06-16T21:59:45.693227Z","extra":{"duration_ms":15000,"file_size":128,"height":720,"thumbnail_url":"/uploads/thumb/2026/06/8e57ff9b-1004-4282-95cd-014dc8ddab3f.jpg","width":1280},"id":"f71b5681-31a5-46f9-adaa-6a8df54c10b9","msg_type":2,"sender_id":2,"seq":6,"status":0}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/conversations/5cf31a40-473d-4aa9-8208-320e29f98b5b/messages"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyMjUxOTg1LCJpYXQiOjE3ODE2NDcxODV9.rCbkWzYq8CjyLgp2MfgnxoG41jerLuK5X1RFUhJsWtg"
```