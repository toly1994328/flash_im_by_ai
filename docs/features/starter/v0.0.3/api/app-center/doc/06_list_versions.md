# GET /api/app/versions?app_id=test_app

获取某应用的全部版本记录（所有平台），按创建时间降序。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| app_id | string | 是 | 应用标识 |

## Response `200`

```json
[{"id":3,"platform":"windows","version":"0.1.0","download_url":"https://example.com/test_app_0.1.0.exe","file_size":10000000,"sha256":"test_hash_123","release_notes":"测试版本","force_update":false,"created_at":"2026-06-05T22:31:45.793695Z"}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/app/versions?app_id=test_app"
```