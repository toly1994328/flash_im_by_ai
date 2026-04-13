# GET /conversations/search

空关键词返回空列表。

## Response `200`

```json
[]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations/search"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.e2lTgvQvUYvq00t9MNlOiNh1Pc66a5qoJGf-fx_5rws"
```

> 防止无意义的全表扫描。