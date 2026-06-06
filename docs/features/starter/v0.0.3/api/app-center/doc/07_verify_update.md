# GET /api/app/version?app_id=1&platform=android

验证版本信息已被正确更新。

## Response `200`

```json
{"version":"1.0.0","download_url":"https://example.com/flash_im_1.0.0.apk","file_size":25000000,"sha256":"abc123def456","release_notes":"首个版本发布（更新说明修正）","force_update":true}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/app/version?app_id=1&platform=android"
```

> force_update 已变为 true，release_notes 已更新