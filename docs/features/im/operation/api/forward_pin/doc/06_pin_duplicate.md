# POST /conversations/{conv_id}/messages/pin

重复置顶同一条消息（应返回 400）

## Response `400`

```json
{"error":"消息已置顶","status":400}
```

> 消息已置顶