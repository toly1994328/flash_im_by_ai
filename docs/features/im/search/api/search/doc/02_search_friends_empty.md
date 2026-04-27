# GET /api/friends/search?keyword=不存在的名字xyz

搜索好友，无匹配结果时返回空数组。

## Response `200`

```json
{"data":[]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/friends/search?keyword=不存在的名字xyz"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3ODE5ODgwLCJpYXQiOjE3NzcyMTUwODB9.G3K0pR5JybdqIG7bzZP6WloATsEl1_ujoxoX4pztqZA"
```

> 关键词无匹配时返回 200 + 空数组，不返回 404。