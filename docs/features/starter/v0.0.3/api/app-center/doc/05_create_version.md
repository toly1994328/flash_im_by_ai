# POST /api/app/version

新增版本记录。发布新版本时调用。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| app_id | string | 是 | 应用标识 |
| platform | string | 是 | 平台 |
| version | string | 是 | 版本号 |
| download_url | string | 是 | 下载地址 |
| file_size | int | 否 | 文件大小 |
| sha256 | string | 否 | 文件哈希 |
| release_notes | string | 否 | 更新日志 |
| force_update | bool | 否 | 是否强制更新 |

```json
{"app_id": "test_app", "platform": "windows", "version": "0.1.0", "download_url": "https://example.com/test_app_0.1.0.exe", "file_size": 10000000, "sha256": "test_hash_123", "release_notes": "\u6d4b\u8bd5\u7248\u672c", "force_update": false}
```

## Response `201`

```json
{"message":"version created"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/app/version"
  -H "Content-Type: application/json"
  -d '{"app_id": "test_app", "platform": "windows", "version": "0.1.0", "download_url": "https://example.com/test_app_0.1.0.exe", "file_size": 10000000, "sha256": "test_hash_123", "release_notes": "\u6d4b\u8bd5\u7248\u672c", "force_update": false}'
```