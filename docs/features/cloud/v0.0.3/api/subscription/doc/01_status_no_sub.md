# GET /api/subscriptions/status

查询当前用户订阅状态（无订阅时）。

## Response `200`

```json
{"has_active_subscription":false,"plan_code":null,"plan_name":null,"expires_at":null,"oss_upload_enabled":false,"quota":{"used_bytes":96386165,"quota_bytes":104857600}}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/subscriptions/status"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyNjE2MzQzLCJpYXQiOjE3ODIwMTE1NDN9.hOIXWaFEm4WW3UP39oexFGwV-OKaNI9OBnVoA04fFdE"
```