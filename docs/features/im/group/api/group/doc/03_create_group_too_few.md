# POST /groups

成员不足时返回 400（加上群主至少 3 人）。

```json
{"name": "\u592a\u5c11\u4e86", "member_ids": [2]}
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
  -d '{"name": "\u592a\u5c11\u4e86", "member_ids": [2]}'
```

> member_ids 去重后加群主不足 3 人时拒绝。