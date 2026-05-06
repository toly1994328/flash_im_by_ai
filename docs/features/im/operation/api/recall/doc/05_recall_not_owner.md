# POST /conversations/bad76d18-338e-4d86-bd68-3cea87aad5bf/messages/41e23b41-5144-4441-91e3-797e1255cc61/recall

B 尝试撤回 A 的消息（应返回 403）

## Response `403`

```json
{"error":"只能撤回自己的消息","status":403}
```

> 只能撤回自己的消息