# POST /auth/login

使用邮箱验证码登录。首次登录自动注册。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | string | 是 | 邮箱地址（复用 phone 字段） |
| type | string | 是 | 登录类型：email |
| credential | string | 是 | 验证码或密码 |

```json
{"phone": "test@example.com", "type": "email", "credential": "207076"}
```

## Response `200`

```json
{"token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgwMjE3NzA2LCJpYXQiOjE3Nzk2MTI5MDZ9.w8EYLRudRQTlSwoJ6ZEAmlSoKuOarepaSHatlN4Z_ks","user_id":2,"has_password":false}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/auth/login"
  -H "Content-Type: application/json"
  -d '{"phone": "test@example.com", "type": "email", "credential": "207076"}'
```