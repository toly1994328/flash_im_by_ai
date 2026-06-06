# GET /api/app/version?app_id=1&platform=android

查询指定应用在指定平台的最新版本。客户端启动时调用。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| app_id | string | 是 | 应用标识 |
| platform | string | 是 | 平台标识 |

## Response `200`

```json
{"version":"1.0.0","download_url":"https://example.com/flash_im_1.0.0.apk","file_size":25000000,"sha256":"abc123def456","release_notes":"首个版本发布","force_update":false}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/app/version?app_id=1&platform=android"
```