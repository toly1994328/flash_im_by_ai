# PUT /api/app/version?app_id=1&platform=android&version=9.9.9

更新不存在的版本，返回 404。

```json
{"release_notes": "\u9996\u4e2a\u7248\u672c\u53d1\u5e03\uff08\u66f4\u65b0\u8bf4\u660e\u4fee\u6b63\uff09", "force_update": true}
```

## Response `404`

```json
{"error":"version not found","status":404}
```

## curl

```bash
curl -s -X PUT "http://127.0.0.1:9600/api/app/version?app_id=1&platform=android&version=9.9.9"
  -H "Content-Type: application/json"
  -d '{"release_notes": "\u9996\u4e2a\u7248\u672c\u53d1\u5e03\uff08\u66f4\u65b0\u8bf4\u660e\u4fee\u6b63\uff09", "force_update": true}'
```

> 版本记录不存在时无法更新