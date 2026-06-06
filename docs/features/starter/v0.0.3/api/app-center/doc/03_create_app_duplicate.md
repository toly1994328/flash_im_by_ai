# POST /api/app

重复新增同一应用，返回错误。

```json
{"id": "test_app", "name": "\u6d4b\u8bd5\u5e94\u7528", "description": "\u7528\u4e8e\u6d4b\u8bd5\u7684\u5e94\u7528"}
```

## Response `400`

```json
{"error":"app already exists","status":400}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/app"
  -H "Content-Type: application/json"
  -d '{"id": "test_app", "name": "\u6d4b\u8bd5\u5e94\u7528", "description": "\u7528\u4e8e\u6d4b\u8bd5\u7684\u5e94\u7528"}'
```

> app id 已存在时返回 400