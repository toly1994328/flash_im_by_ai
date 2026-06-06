# POST /api/app

新增应用。注册一个新的应用到系统中。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | string | 是 | 应用唯一标识 |
| name | string | 是 | 应用名称 |
| description | string | 否 | 应用描述 |

```json
{"id": "test_app", "name": "\u6d4b\u8bd5\u5e94\u7528", "description": "\u7528\u4e8e\u6d4b\u8bd5\u7684\u5e94\u7528"}
```

## Response `201`

```json
{"message":"app created"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/app"
  -H "Content-Type: application/json"
  -d '{"id": "test_app", "name": "\u6d4b\u8bd5\u5e94\u7528", "description": "\u7528\u4e8e\u6d4b\u8bd5\u7684\u5e94\u7528"}'
```