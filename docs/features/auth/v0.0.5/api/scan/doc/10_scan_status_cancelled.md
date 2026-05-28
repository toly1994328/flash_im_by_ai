# GET /auth/scan/status?token=f753365e-1a82-44a5-a01c-e7537a512093

查询已取消的扫码会话状态。

## Response `200`

```json
{"status":"cancelled"}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/auth/scan/status?token=f753365e-1a82-44a5-a01c-e7537a512093"
```