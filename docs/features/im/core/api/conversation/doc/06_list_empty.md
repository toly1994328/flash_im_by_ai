# GET /conversations?limit=20&offset=100

偏移量超出总数时返回空数组。

## Response `200`

```json
[]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations?limit=20&offset=100"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc1NDA1OTIyLCJpYXQiOjE3NzQ4MDExMjJ9.giI1rG-7ytHzmEykcXLygkv98s60ITQA3fVgBRiH8gY"
```