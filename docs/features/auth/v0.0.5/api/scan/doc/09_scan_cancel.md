# POST /auth/scan/cancel

手机端取消扫码登录。需要手机端 JWT 认证。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| scan_token | string | 是 | 扫码会话 token |

```json
{"scan_token": "f753365e-1a82-44a5-a01c-e7537a512093"}
```

## Response `200`

```json
{"message":"ok"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/auth/scan/cancel"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgwNTI3NjAzLCJpYXQiOjE3Nzk5MjI4MDN9.q5d8vbiaZiSnzhp7bCnUa2L23yKUCv4tqgWg_1B8kCg"
  -H "Content-Type: application/json"
  -d '{"scan_token": "f753365e-1a82-44a5-a01c-e7537a512093"}'
```