# GET /conversations/294588ba-f96e-4ced-9d7c-b73bd6f66117/messages?after_seq=0&limit=5

增量同步（新功能）：返回 seq > after_seq 的消息，按 seq ASC 排序。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| after_seq | int | 否 | 返回 seq 大于此值的消息 |
| limit | int | 否 | 返回条数 |

## Response `200`

```json
[{"content":"我们已经是好友了，开始聊天吧","conversation_id":"294588ba-f96e-4ced-9d7c-b73bd6f66117","created_at":"2026-04-26T14:33:47.563934Z","extra":null,"id":"839996f7-1f79-4674-982c-4658845d2308","msg_type":0,"sender_avatar":"identicon:朱红:ed5126","sender_id":1,"sender_name":"朱红","seq":1,"status":0},{"content":"我是朱红","conversation_id":"294588ba-f96e-4ced-9d7c-b73bd6f66117","created_at":"2026-04-26T23:01:59.050253Z","extra":null,"id":"0b1b7d99-620f-4637-9467-506f7e213cad","msg_type":0,"sender_avatar":"identicon:朱红:ed5126","sender_id":1,"sender_name":"朱红","seq":2,"status":0}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations/294588ba-f96e-4ced-9d7c-b73bd6f66117/messages?after_seq=0&limit=5"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc4MDIzMjY1LCJpYXQiOjE3Nzc0MTg0NjV9.RhIIUK4RoFV_1o84WPRFu6l_CR53CFjGK3v-ftBpwE0"
```

> after_seq 和 before_seq 同时传时，after_seq 优先。排序为 ASC（从旧到新），和 before_seq 的 DESC 相反。