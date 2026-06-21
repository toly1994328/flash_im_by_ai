# GET /api/subscriptions/status

查询当前用户订阅状态（有活跃订阅时）。

## Response `200`

```json
{"has_active_subscription":true,"plan_code":"cloud_pro","plan_name":"Cloud Pro","expires_at":"2026-07-21T03:12:23.612970Z","oss_upload_enabled":true,"quota":{"used_bytes":96386165,"quota_bytes":1178599424}}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/subscriptions/status"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyNjE2MzQzLCJpYXQiOjE3ODIwMTE1NDN9.hOIXWaFEm4WW3UP39oexFGwV-OKaNI9OBnVoA04fFdE"
```