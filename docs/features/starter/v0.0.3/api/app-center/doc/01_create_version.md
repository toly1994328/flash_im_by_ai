# POST /api/app/version

新增版本记录。发布新版本时调用。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| app_id | string | 是 | 应用标识 |
| platform | string | 是 | 平台（android/ios/windows/macos/linux/ohos） |
| version | string | 是 | 版本号（x.y.z） |
| download_url | string | 是 | 安装包下载地址 |
| file_size | int | 否 | 文件大小（字节） |
| sha256 | string | 否 | 文件 SHA256 哈希 |
| release_notes | string | 否 | 更新日志 |
| force_update | bool | 否 | 是否强制更新 |

```json
{"app_id": "1", "platform": "android", "version": "1.0.0", "download_url": "https://example.com/flash_im_1.0.0.apk", "file_size": 25000000, "sha256": "abc123def456", "release_notes": "\u9996\u4e2a\u7248\u672c\u53d1\u5e03", "force_update": false}
```

## Response `201`

```json
{"message":"version created"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/app/version"
  -H "Content-Type: application/json"
  -d '{"app_id": "1", "platform": "android", "version": "1.0.0", "download_url": "https://example.com/flash_im_1.0.0.apk", "file_size": 25000000, "sha256": "abc123def456", "release_notes": "\u9996\u4e2a\u7248\u672c\u53d1\u5e03", "force_update": false}'
```