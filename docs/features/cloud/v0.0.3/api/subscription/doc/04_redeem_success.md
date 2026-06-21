# POST /api/subscriptions/redeem

使用有效兑换码激活订阅。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| code | string | 是 | 兑换码 |

```json
{"code": "TEST-PRO-2026"}
```

## Response `200`

```json
{"subscription":{"id":6,"plan_code":"cloud_pro","plan_name":"Cloud Pro","status":"active","starts_at":"2026-06-21T03:12:23.612970Z","expires_at":"2026-07-21T03:12:23.612970Z","storage_bytes":1073741824},"quota":{"used_bytes":96386165,"quota_bytes":1178599424}}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/subscriptions/redeem"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyNjE2MzQzLCJpYXQiOjE3ODIwMTE1NDN9.hOIXWaFEm4WW3UP39oexFGwV-OKaNI9OBnVoA04fFdE"
  -H "Content-Type: application/json"
  -d '{"code": "TEST-PRO-2026"}'
```