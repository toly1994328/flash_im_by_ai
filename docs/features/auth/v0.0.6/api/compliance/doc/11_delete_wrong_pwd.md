# POST /api/account/delete

注销账号 - 密码错误。

```json
{"password": "wrongpass"}
```

## Response `401`

```json
{"error":"Unauthorized","status":401}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/account/delete"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0IiwiZXhwIjoxNzgxNzM5MjA4LCJpYXQiOjE3ODExMzQ0MDh9.STe4bCQO2G0_1o8B0YmpUmJB-ZRHjrURWWSyJrDYjsI"
  -H "Content-Type: application/json"
  -d '{"password": "wrongpass"}'
```

> 错误场景：密码验证失败