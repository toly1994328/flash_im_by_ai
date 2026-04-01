# GET /conversations?limit=1&offset=0

分页查询会话列表。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| limit | int | 否 | 每页条数，默认 20 |
| offset | int | 否 | 偏移量，默认 0 |

## Response `200`

```json
[{"avatar":"identicon:52:681752","conv_type":0,"created_at":"2026-03-29T02:59:10.546165Z","id":"e8c1926c-46e1-489a-9037-96612f5c7b93","is_muted":false,"is_pinned":false,"last_message_at":null,"last_message_preview":null,"name":"牵牛紫","peer_avatar":"identicon:52:681752","peer_nickname":"牵牛紫","peer_user_id":"52","unread_count":0}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations?limit=1&offset=0"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc1NDA1OTIyLCJpYXQiOjE3NzQ4MDExMjJ9.giI1rG-7ytHzmEykcXLygkv98s60ITQA3fVgBRiH8gY"
```