# GET /conversations/bad76d18-338e-4d86-bd68-3cea87aad5bf/messages?limit=5

验证撤回后消息 status=1

## Response `200`

```json
[{"content":"这条消息马上要被撤回","conversation_id":"bad76d18-338e-4d86-bd68-3cea87aad5bf","created_at":"2026-05-06T23:25:57.673669Z","extra":null,"id":"3386c923-d6ed-4e7a-bab2-2ee443272475","msg_type":0,"sender_avatar":"identicon:朱红:ed5126","sender_id":1,"sender_name":"朱红","seq":13,"status":1},{"content":"这条是 A 发的，B 不能撤回","conversation_id":"bad76d18-338e-4d86-bd68-3cea87aad5bf","created_at":"2026-05-06T23:11:07.084974Z","extra":null,"id":"192936d6-67c3-4de3-a718-1fdab2be9d13","msg_type":0,"sender_avatar":"identicon:朱红:ed5126","sender_id":1,"sender_name":"朱红","seq":12,"status":0},{"content":"这条消息马上要被撤回","conversation_id":"bad76d18-338e-4d86-bd68-3cea87aad5bf","created_at":"2026-05-06T23:11:06.953834Z","extra":null,"id":"5d487bd6-902e-4cfc-99ec-3e2465902839","msg_type":0,"sender_avatar":"identicon:朱红:ed5126","sender_id":1,"sender_name":"朱红","seq":11,"status":1},{"content":"3","conversation_id":"bad76d18-338e-4d86-bd68-3cea87aad5bf","created_at":"2026-05-01T18:55:38.136280Z","extra":null,"id":"2fd7ce1e-2a5c-41ab-b9ed-0ab52b991184","msg_type":0,"sender_avatar":"identicon:朱红:ed5126","sender_id":1,"sender_name":"朱红","seq":10,"status":1},{"content":"2","conversation_id":"bad76d18-338e-4d86-bd68-3cea87aad5bf","created_at":"2026-05-01T18:55:24.578826Z","extra":null,"id":"8a864792-4cc1-471a-b2ee-dc58778a3226","msg_type":0,"sender_avatar":"identicon:朱红:ed5126","sender_id":1,"sender_name":"朱红","seq":9,"status":0}]
```