# GET /conversations

会话列表包含群聊，群聊显示群名和宫格头像。

## Response `200`

```json
[{"avatar":"identicon:2","conv_type":0,"created_at":"2026-04-12T14:40:38.094159Z","id":"b5ffb276-bcd3-42c0-a5b4-8217e3f8b1d9","is_muted":false,"is_pinned":false,"last_message_at":null,"last_message_preview":null,"name":"用户0002","peer_avatar":"identicon:2","peer_nickname":"用户0002","peer_user_id":"2","unread_count":0},{"avatar":"identicon:5","conv_type":0,"created_at":"2026-04-12T14:40:38.053508Z","id":"5f98c0c5-2b1d-4ae8-9adb-af1d2f303e12","is_muted":false,"is_pinned":false,"last_message_at":null,"last_message_preview":null,"name":"用户0005","peer_avatar":"identicon:5","peer_nickname":"用户0005","peer_user_id":"5","unread_count":0},{"avatar":"grid:identicon:1,identicon:2,identicon:3,identicon:4","conv_type":1,"created_at":"2026-04-12T14:40:37.937647Z","id":"890056e8-8d10-4e40-82a8-a8810ff7374d","is_muted":false,"is_pinned":false,"last_message_at":null,"last_message_preview":null,"name":"测试群聊","peer_avatar":null,"peer_nickname":null,"peer_user_id":null,"unread_count":0}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.e2lTgvQvUYvq00t9MNlOiNh1Pc66a5qoJGf-fx_5rws"
```

> 群聊的 name 来自 conversations.name，avatar 来自 conversations.avatar（grid: 格式）。