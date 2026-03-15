# POST /auth/sms — 发送验证码

## 请求

```bash
curl -X POST http://127.0.0.1:9600/auth/sms \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}'
```

## 响应（200）

```json
{
  "code": "360410",
  "message": "验证码已发送"
}
```

## 说明

- 模拟接口，返回 6 位随机验证码
- 验证码同时会打印在服务端控制台
- 手机号必须 11 位且以 1 开头，否则返回 400
