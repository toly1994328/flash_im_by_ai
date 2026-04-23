# PUT /groups/0756c679-62de-4f8f-a274-43d29187d18b/transfer

非群主转让返回 403。uid1 已不是群主，无权转让。

```json
{"new_owner_id": 3}
```

## Response `403`

```json
(empty body)
```

## curl

```bash
curl -s -X PUT "http://127.0.0.1:9600/groups/0756c679-62de-4f8f-a274-43d29187d18b/transfer"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3NTA2ODU0LCJpYXQiOjE3NzY5MDIwNTR9.OvMfZ0nEOPIxrXAWzv7wrfR8YEUsQFQljufpASuRvOU"
  -H "Content-Type: application/json"
  -d '{"new_owner_id": 3}'
```

> 只有当前群主可以转让。