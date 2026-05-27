# POST /auth/email/code

60 秒内同一邮箱或同一 IP 重复请求，返回 429。

```json
{"email": "test@example.com"}
```

## Response `429`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/auth/email/code"
  -H "Content-Type: application/json"
  -d '{"email": "test@example.com"}'
```

> 频率限制：同一邮箱或同一 IP 60 秒内只能发一次