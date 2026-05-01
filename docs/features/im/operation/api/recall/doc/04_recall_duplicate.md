# POST /conversations/bad76d18-338e-4d86-bd68-3cea87aad5bf/messages/b83d0207-9765-4a7d-8b5a-5483e68b9f8d/recall

重复撤回同一条消息（应返回 400）

## Response `400`

```json
{"error":"消息已撤回","status":400}
```

> 消息已撤回，不能重复操作