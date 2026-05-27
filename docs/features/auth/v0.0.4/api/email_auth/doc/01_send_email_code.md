# POST /auth/email/code

发送邮箱验证码。debug 模式下直接返回验证码。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 邮箱地址 |

```json
{"email": "test@example.com"}
```

## Response `200`

```json
{"code":"207076","message":"验证码已发送(debug)"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/auth/email/code"
  -H "Content-Type: application/json"
  -d '{"email": "test@example.com"}'
```