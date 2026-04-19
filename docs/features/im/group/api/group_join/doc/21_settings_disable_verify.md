# PUT /groups/5aaebb83-19e1-45e7-891c-3a2b2775a9ea/settings

群主关闭入群验证。

```json
{"join_verification": false}
```

## Response `200`

```json
{"success":true}
```

## curl

```bash
curl -s -X PUT "http://127.0.0.1:9600/groups/5aaebb83-19e1-45e7-891c-3a2b2775a9ea/settings"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9.bkyRhLQ92eyB0vtIv1jP5wvukqHFuP4pNzpFHVO0-0U"
  -H "Content-Type: application/json"
  -d '{"join_verification": false}'
```