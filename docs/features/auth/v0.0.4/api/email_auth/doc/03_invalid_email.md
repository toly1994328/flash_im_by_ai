# POST /auth/email/code

邮箱格式无效时返回 400。

```json
{"email": "not-an-email"}
```

## Response `400`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/auth/email/code"
  -H "Content-Type: application/json"
  -d '{"email": "not-an-email"}'
```

> 邮箱必须包含 @ 和 .