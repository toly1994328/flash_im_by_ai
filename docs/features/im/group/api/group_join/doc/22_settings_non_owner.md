# PUT /groups/5aaebb83-19e1-45e7-891c-3a2b2775a9ea/settings

非群主修改群设置返回 403。

```json
{"join_verification": true}
```

## Response `403`

```json
(empty body)
```

## curl

```bash
curl -s -X PUT "http://127.0.0.1:9600/groups/5aaebb83-19e1-45e7-891c-3a2b2775a9ea/settings"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9.MBxC1j8_7j8yAwmsb2EcLsive56tPI8HF0ZpWj4bmK0"
  -H "Content-Type: application/json"
  -d '{"join_verification": true}'
```

> 只有群主可以修改群设置。