# GET /auth/scan/status?token=1a7d3f1e-2e4c-4ed6-b208-7977098d87e3

查询扫码会话状态，已确认，返回桌面端 JWT token 和 user_id。

## Response `200`

```json
{"status":"confirmed","token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgwNTI3NjAzLCJpYXQiOjE3Nzk5MjI4MDN9.q5d8vbiaZiSnzhp7bCnUa2L23yKUCv4tqgWg_1B8kCg","user_id":2}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/auth/scan/status?token=1a7d3f1e-2e4c-4ed6-b208-7977098d87e3"
```

> 桌面端拿到 token 后保存，进入主页