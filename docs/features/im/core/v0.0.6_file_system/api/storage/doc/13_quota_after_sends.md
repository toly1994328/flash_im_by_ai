# GET /api/storage/quota

发送多种媒体消息后查询配额，验证用量正确增长。

## Response `200`

```json
{"used_bytes":483,"quota_bytes":104857600,"breakdown":{"file":{"size":190,"count":1},"image":{"size":69,"count":1},"audio":{"size":96,"count":1},"video":{"size":128,"count":1}}}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/storage/quota"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyMjUxOTg1LCJpYXQiOjE3ODE2NDcxODV9.rCbkWzYq8CjyLgp2MfgnxoG41jerLuK5X1RFUhJsWtg"
```

> used_bytes 应大于 0，breakdown 包含各类型文件用量。