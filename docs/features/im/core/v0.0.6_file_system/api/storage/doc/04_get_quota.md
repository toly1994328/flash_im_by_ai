# GET /api/storage/quota

查询当前用户的云空间配额和分类用量。

## Response `200`

```json
{"used_bytes":259,"quota_bytes":104857600,"breakdown":{"image":{"size":69,"count":1},"file":{"size":190,"count":1}}}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/storage/quota"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyMjUxOTg1LCJpYXQiOjE3ODE2NDcxODV9.rCbkWzYq8CjyLgp2MfgnxoG41jerLuK5X1RFUhJsWtg"
```