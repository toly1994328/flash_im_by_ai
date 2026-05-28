# POST /auth/scan/create

创建扫码登录会话，返回二维码内容。桌面端调用。

## Response `200`

```json
{"token":"1a7d3f1e-2e4c-4ed6-b208-7977098d87e3","qr_content":"flash://scan/1a7d3f1e-2e4c-4ed6-b208-7977098d87e3","expires_at":"2026-05-27T23:05:03.102881Z"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/auth/scan/create"
```

> 无需认证，桌面端未登录时调用