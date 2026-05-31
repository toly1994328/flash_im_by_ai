# GET /auth/scan/status?token=1a7d3f1e-2e4c-4ed6-b208-7977098d87e3

查询扫码会话状态，已扫码等待确认。

## Response `200`

```json
{"status":"scanned"}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/auth/scan/status?token=1a7d3f1e-2e4c-4ed6-b208-7977098d87e3"
```