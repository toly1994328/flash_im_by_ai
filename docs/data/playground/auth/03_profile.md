# GET /user/profile — 获取用户信息

## 请求

```bash
curl http://127.0.0.1:9600/user/profile \
  -H "Authorization: Bearer <token>"
```

## 响应（200）

```json
{
  "user_id": 1,
  "phone": "13800138000",
  "nickname": "13800138000",
  "avatar": "https://picsum.photos/seed/1/100/100"
}
```

## 异常场景

| 场景 | 状态码 |
|------|--------|
| 不带 Token | 401 |
| 伪造/过期 Token | 401 |
| Token 有效但用户不存在 | 404 |

## 说明

- 需要在请求头携带 `Authorization: Bearer {token}`
- Token 从 `/auth/login` 接口获取
- 从 JWT Payload 中解析 user_id，查找对应用户信息
