# GET /conversations/294588ba-f96e-4ced-9d7c-b73bd6f66117/messages?after_seq=1&limit=5

增量同步：after_seq=1，只返回比这个 seq 更新的消息。

## Response `200`

```json
[{"content":"我是朱红","conversation_id":"294588ba-f96e-4ced-9d7c-b73bd6f66117","created_at":"2026-04-26T23:01:59.050253Z","extra":null,"id":"0b1b7d99-620f-4637-9467-506f7e213cad","msg_type":0,"sender_avatar":"identicon:朱红:ed5126","sender_id":1,"sender_name":"朱红","seq":2,"status":0}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations/294588ba-f96e-4ced-9d7c-b73bd6f66117/messages?after_seq=1&limit=5"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc4MDIzMjY1LCJpYXQiOjE3Nzc0MTg0NjV9.RhIIUK4RoFV_1o84WPRFu6l_CR53CFjGK3v-ftBpwE0"
```