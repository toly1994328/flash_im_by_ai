# GET /conversations/bad76d18-338e-4d86-bd68-3cea87aad5bf/messages?limit=5

验证撤回后消息 status=1

## Response `200`

```json
[{"content":"这条消息马上要被撤回","conversation_id":"bad76d18-338e-4d86-bd68-3cea87aad5bf","created_at":"2026-05-01T01:10:25.003039Z","extra":null,"id":"b83d0207-9765-4a7d-8b5a-5483e68b9f8d","msg_type":0,"sender_avatar":"identicon:朱红:ed5126","sender_id":1,"sender_name":"朱红","seq":2,"status":1},{"content":"我们已经是好友了，开始聊天吧","conversation_id":"bad76d18-338e-4d86-bd68-3cea87aad5bf","created_at":"2026-04-26T14:33:43.196359Z","extra":null,"id":"50fdb7d9-ac36-4e4d-ada5-0d3a07e7f236","msg_type":0,"sender_avatar":"identicon:朱红:ed5126","sender_id":1,"sender_name":"朱红","seq":1,"status":0}]
```