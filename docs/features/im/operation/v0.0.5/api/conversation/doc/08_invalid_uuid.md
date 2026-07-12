# POST /conversations/not-a-uuid/pin

会话 ID 格式非法（非 UUID），返回 400。

## Response `400`

```json
(empty)
```

> 路由层 Uuid::parse_str 失败即返回 400。