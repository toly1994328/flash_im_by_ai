# POST /api/app/version

重复新增同一版本，返回错误。

```json
{"app_id": "1", "platform": "android", "version": "1.0.0", "download_url": "https://example.com/flash_im_1.0.0.apk", "file_size": 25000000, "sha256": "abc123def456", "release_notes": "\u9996\u4e2a\u7248\u672c\u53d1\u5e03", "force_update": false}
```

## Response `400`

```json
{"error":"version already exists","status":400}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/app/version"
  -H "Content-Type: application/json"
  -d '{"app_id": "1", "platform": "android", "version": "1.0.0", "download_url": "https://example.com/flash_im_1.0.0.apk", "file_size": 25000000, "sha256": "abc123def456", "release_notes": "\u9996\u4e2a\u7248\u672c\u53d1\u5e03", "force_update": false}'
```

> 同一 app_id + platform + version 不能重复