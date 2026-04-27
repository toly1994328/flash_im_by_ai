# GET /api/messages/search?keyword=完全不存在的内容xyz

消息搜索无匹配时返回空数组。

## Response `200`

```json
{"data":[]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/messages/search?keyword=完全不存在的内容xyz"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3ODE5ODgwLCJpYXQiOjE3NzcyMTUwODB9.G3K0pR5JybdqIG7bzZP6WloATsEl1_ujoxoX4pztqZA"
```