# GET /api/app/version?app_id=test_app&platform=windows

查询指定应用在指定平台的最新版本。客户端启动时调用。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| app_id | string | 是 | 应用标识 |
| platform | string | 是 | 平台标识 |

## Response `200`

```json
{"version":"0.1.0","download_url":"https://example.com/test_app_0.1.0.exe","file_size":10000000,"sha256":"test_hash_123","release_notes":"测试版本","force_update":false}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/app/version?app_id=test_app&platform=windows"
```