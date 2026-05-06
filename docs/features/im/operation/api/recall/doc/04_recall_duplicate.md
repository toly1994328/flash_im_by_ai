# POST /conversations/bad76d18-338e-4d86-bd68-3cea87aad5bf/messages/3386c923-d6ed-4e7a-bab2-2ee443272475/recall

重复撤回同一条消息（应返回 400）

## Response `400`

```json
{"error":"消息已撤回","status":400}
```

> 消息已撤回，不能重复操作