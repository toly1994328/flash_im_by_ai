# GET /auth/scan/status?token=1a7d3f1e-2e4c-4ed6-b208-7977098d87e3

查询扫码会话状态。桌面端轮询调用。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| token | string | 是 | 扫码会话 token（query 参数） |

## Response `200`

```json
{"status":"pending"}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/auth/scan/status?token=1a7d3f1e-2e4c-4ed6-b208-7977098d87e3"
```