# POST /auth/scan/confirm

手机端扫码，标记会话为已扫码。需要手机端 JWT 认证。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| scan_token | string | 是 | 扫码会话 token |
| action | string | 是 | 动作：scan 或 confirm |

```json
{"scan_token": "1a7d3f1e-2e4c-4ed6-b208-7977098d87e3", "action": "scan"}
```

## Response `200`

```json
{"message":"ok"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/auth/scan/confirm"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgwNTI3NjAzLCJpYXQiOjE3Nzk5MjI4MDN9.q5d8vbiaZiSnzhp7bCnUa2L23yKUCv4tqgWg_1B8kCg"
  -H "Content-Type: application/json"
  -d '{"scan_token": "1a7d3f1e-2e4c-4ed6-b208-7977098d87e3", "action": "scan"}'
```