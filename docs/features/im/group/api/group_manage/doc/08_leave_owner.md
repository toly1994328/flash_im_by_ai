# POST /groups/0756c679-62de-4f8f-a274-43d29187d18b/leave

群主不能退群，返回 400。群主必须先转让或解散。

## Response `400`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/0756c679-62de-4f8f-a274-43d29187d18b/leave"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3NTA2ODU0LCJpYXQiOjE3NzY5MDIwNTR9.OvMfZ0nEOPIxrXAWzv7wrfR8YEUsQFQljufpASuRvOU"
```

> 群主不能退群，避免群变成无主状态。