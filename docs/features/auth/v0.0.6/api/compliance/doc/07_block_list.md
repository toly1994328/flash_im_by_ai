# GET /api/blocks

获取黑名单列表。

## Response `200`

```json
{"data":[{"avatar":"identicon:3","blocked_at":"2026-06-10T23:33:28Z","nickname":"用户0002","user_id":"3"}]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/blocks"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgxNzM5MjA4LCJpYXQiOjE3ODExMzQ0MDh9.EMBPh2qwXnrst4SJ4KfJqmrnmTVI6_f7xTosC3742NE"
```