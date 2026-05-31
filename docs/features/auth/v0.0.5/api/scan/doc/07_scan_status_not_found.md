# GET /auth/scan/status?token=invalid-token-xxx

查询不存在的扫码会话，返回 404。

## Response `404`

```json
(empty body)
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/auth/scan/status?token=invalid-token-xxx"
```

> 错误场景：token 不存在