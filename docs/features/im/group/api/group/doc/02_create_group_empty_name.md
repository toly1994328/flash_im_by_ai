# POST /groups

群名为空时返回 400。

```json
{"name": "", "member_ids": [2, 3]}
```

## Response `400`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MDUxMzA2LCJpYXQiOjE3NzY0NDY1MDZ9.RnddDHuGfJO_OhSBvfI0r626elwvlXOR-DZWQhRlKrA"
  -H "Content-Type: application/json"
  -d '{"name": "", "member_ids": [2, 3]}'
```

> 群名 trim 后为空即拒绝。