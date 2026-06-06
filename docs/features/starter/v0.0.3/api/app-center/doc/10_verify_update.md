# GET /api/app/version?app_id=test_app&platform=windows

验证版本信息已被正确更新。

## Response `200`

```json
{"version":"0.1.0","download_url":"https://example.com/test_app_0.1.0.exe","file_size":10000000,"sha256":"test_hash_123","release_notes":"测试版本（已修正）","force_update":true}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/app/version?app_id=test_app&platform=windows"
```

> force_update 已变为 true，release_notes 已更新