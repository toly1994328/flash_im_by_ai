# DELETE /groups/0756c679-62de-4f8f-a274-43d29187d18b/members/5

群主踢人。被踢成员的 is_deleted 标记为 true，刷新宫格头像 + 发送系统消息。

## Response `200`

```json
{"success":true}
```

## curl

```bash
curl -s -X DELETE "http://127.0.0.1:9600/groups/0756c679-62de-4f8f-a274-43d29187d18b/members/5"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3NTA2ODU0LCJpYXQiOjE3NzY5MDIwNTR9.OvMfZ0nEOPIxrXAWzv7wrfR8YEUsQFQljufpASuRvOU"
```

> 只有群主可以踢人。