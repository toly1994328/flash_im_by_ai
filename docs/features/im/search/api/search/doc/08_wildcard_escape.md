# GET /api/friends/search?keyword=%25

搜索关键词包含 SQL 通配符（%、_）时正确转义，不报错。

## Response `200`

```json
{"data":[]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/friends/search?keyword=%25"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3ODE5ODgwLCJpYXQiOjE3NzcyMTUwODB9.G3K0pR5JybdqIG7bzZP6WloATsEl1_ujoxoX4pztqZA"
```

> 后端对 % 和 _ 做了转义（\% 和 \_），防止 ILIKE 注入。