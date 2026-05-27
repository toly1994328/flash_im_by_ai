# POST /auth/login

验证码错误且无密码时返回 401。

```json
{"phone": "test@example.com", "type": "email", "credential": "000000"}
```

## Response `401`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/auth/login"
  -H "Content-Type: application/json"
  -d '{"phone": "test@example.com", "type": "email", "credential": "000000"}'
```

> 验证码不匹配，且该邮箱未设置密码，返回 401