# POST /api/subscriptions/redeem

使用无效兑换码（400）。

```json
{"code": "INVALID-CODE"}
```

## Response `400`

```json
{"error":"兑换码无效","status":400}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/subscriptions/redeem"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyNjE2MzQzLCJpYXQiOjE3ODIwMTE1NDN9.hOIXWaFEm4WW3UP39oexFGwV-OKaNI9OBnVoA04fFdE"
  -H "Content-Type: application/json"
  -d '{"code": "INVALID-CODE"}'
```

> 兑换码不存在时返回 400