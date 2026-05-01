# POST /conversations/bad76d18-338e-4d86-bd68-3cea87aad5bf/messages/355bf3e8-5c0a-404a-9c75-63e3938a92a6/recall

B 尝试撤回 A 的消息（应返回 403）

## Response `403`

```json
{"error":"只能撤回自己的消息","status":403}
```

> 只能撤回自己的消息