# GET /api/friends/search?keyword=%25

搜索关键词包含 SQL 通配符（%、_）时正确转义，不报错。

## Response `200`

```json
{"data":[]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/friends/search?keyword=%25"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc4MzcwNDk3LCJpYXQiOjE3Nzc3NjU2OTd9.3woan6cwSZSYb0105mBe1_EocZxGU8-yquq11g8W7ak"
```

> 后端对 % 和 _ 做了转义（\% 和 \_），防止 ILIKE 注入。