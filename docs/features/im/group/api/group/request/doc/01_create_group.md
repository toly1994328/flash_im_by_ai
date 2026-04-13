# POST /conversations

创建群聊会话。群主自动加入，自动生成宫格头像，自动初始化 group_info。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| type | string | 是 | "group" |
| name | string | 是 | 群名称 |
| member_ids | int[] | 是 | 成员 ID 列表（不含群主，至少 2 人） |

```json
{"type": "group", "name": "\u6d4b\u8bd5\u7fa4\u804a", "member_ids": [2, 3, 4]}
```

## Response `200`

```json
{"avatar":"grid:identicon:1,identicon:2,identicon:3,identicon:4","conv_type":1,"created_at":"2026-04-12T14:40:37.937647Z","id":"890056e8-8d10-4e40-82a8-a8810ff7374d","name":"测试群聊","owner_id":"1","peer_avatar":null,"peer_nickname":null,"peer_user_id":null}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/conversations"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.e2lTgvQvUYvq00t9MNlOiNh1Pc66a5qoJGf-fx_5rws"
  -H "Content-Type: application/json"
  -d '{"type": "group", "name": "\u6d4b\u8bd5\u7fa4\u804a", "member_ids": [2, 3, 4]}'
```