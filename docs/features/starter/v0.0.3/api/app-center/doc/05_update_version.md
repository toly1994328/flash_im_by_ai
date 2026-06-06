# PUT /api/app/version?app_id=1&platform=android&version=1.0.0

更新已有版本的信息。修正下载地址、更新日志等。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| app_id | string | 是 | 应用标识（query） |
| platform | string | 是 | 平台标识（query） |
| version | string | 是 | 版本号（query） |
| download_url | string | 否 | 新下载地址（body） |
| file_size | int | 否 | 新文件大小（body） |
| sha256 | string | 否 | 新哈希值（body） |
| release_notes | string | 否 | 新更新日志（body） |
| force_update | bool | 否 | 新强制更新标记（body） |

```json
{"release_notes": "\u9996\u4e2a\u7248\u672c\u53d1\u5e03\uff08\u66f4\u65b0\u8bf4\u660e\u4fee\u6b63\uff09", "force_update": true}
```

## Response `200`

```json
{"message":"version updated"}
```

## curl

```bash
curl -s -X PUT "http://127.0.0.1:9600/api/app/version?app_id=1&platform=android&version=1.0.0"
  -H "Content-Type: application/json"
  -d '{"release_notes": "\u9996\u4e2a\u7248\u672c\u53d1\u5e03\uff08\u66f4\u65b0\u8bf4\u660e\u4fee\u6b63\uff09", "force_update": true}'
```