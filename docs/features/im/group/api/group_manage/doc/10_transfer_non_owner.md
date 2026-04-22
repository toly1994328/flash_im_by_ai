# PUT /groups/33a71c87-efc8-414d-af0e-696879167e33/transfer

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
curl -s -X PUT "http://127.0.0.1:9600/groups/33a71c87-efc8-414d-af0e-696879167e33/transfer"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.5NMBPyBR3-3MvkmY1zDZQLvBUGdVhxW2wpm4Agg4pjE"
  -H "Content-Type: application/json"
  -d '{"new_owner_id": 3}'
```

> 只有当前群主可以转让。