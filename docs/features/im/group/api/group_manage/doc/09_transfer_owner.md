# PUT /groups/0756c679-62de-4f8f-a274-43d29187d18b/transfer

群主转让。owner_id 更新为新群主，发送系统消息。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| new_owner_id | i64 | 是 | 新群主的 user_id（必须是群成员） |

```json
{"new_owner_id": 2}
```

## Response `200`

```json
{"success":true}
```

## curl

```bash
curl -s -X PUT "http://127.0.0.1:9600/groups/0756c679-62de-4f8f-a274-43d29187d18b/transfer"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3NTA2ODU0LCJpYXQiOjE3NzY5MDIwNTR9.OvMfZ0nEOPIxrXAWzv7wrfR8YEUsQFQljufpASuRvOU"
  -H "Content-Type: application/json"
  -d '{"new_owner_id": 2}'
```