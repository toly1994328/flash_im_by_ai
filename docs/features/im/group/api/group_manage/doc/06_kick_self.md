# DELETE /groups/0756c679-62de-4f8f-a274-43d29187d18b/members/1

群主不能踢自己，返回 400。群主需要先转让或解散群聊。

## Response `400`

```json
(empty body)
```

## curl

```bash
curl -s -X DELETE "http://127.0.0.1:9600/groups/0756c679-62de-4f8f-a274-43d29187d18b/members/1"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3NTA2ODU0LCJpYXQiOjE3NzY5MDIwNTR9.OvMfZ0nEOPIxrXAWzv7wrfR8YEUsQFQljufpASuRvOU"
```

> 群主不能踢自己，避免群变成无主状态。