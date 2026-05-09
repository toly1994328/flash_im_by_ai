# POST /conversations/{conv_id}/messages/forward

转发空消息列表（应返回 400）

## Response `400`

```json
{"error":"message_ids 不能为空","status":400}
```

> message_ids 不能为空