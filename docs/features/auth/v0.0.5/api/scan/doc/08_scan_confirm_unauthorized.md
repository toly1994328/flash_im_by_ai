# POST /auth/scan/confirm

未携带 JWT 认证的扫码请求，返回 401。

```json
{"scan_token": "f753365e-1a82-44a5-a01c-e7537a512093", "action": "scan"}
```

## Response `401`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/auth/scan/confirm"
  -H "Content-Type: application/json"
  -d '{"scan_token": "f753365e-1a82-44a5-a01c-e7537a512093", "action": "scan"}'
```

> 错误场景：手机端未登录