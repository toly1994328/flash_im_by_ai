# POST /auth/login — 验证码登录

## 请求

```bash
curl -X POST http://127.0.0.1:9600/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"360410"}'
```

## 响应（200）

```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc0MTUyMTQ3LCJpYXQiOjE3NzM1NDczNDd9.3UxyRjevy3MFaT-mQZpX1NT6-ykjZIvVP2gXwDWp89Q",
  "user_id": 1
}
```

## 异常场景

| 场景 | 状态码 |
|------|--------|
| 手机号格式错误（非11位/不以1开头） | 400 |
| 验证码错误 | 401 |

## 说明

- 登录即注册：手机号不存在时自动创建用户，默认昵称为手机号
- 验证码使用后自动失效，需重新获取
- 返回的 JWT Token 有效期 7 天
