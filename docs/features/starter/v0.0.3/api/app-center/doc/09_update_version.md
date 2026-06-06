# PUT /api/app/version?app_id=test_app&platform=windows&version=0.1.0

更新已有版本的信息。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| app_id | string | 是 | 应用标识（query） |
| platform | string | 是 | 平台（query） |
| version | string | 是 | 版本号（query） |
| release_notes | string | 否 | 新更新日志（body） |
| force_update | bool | 否 | 新强制更新标记（body） |

```json
{"release_notes": "\u6d4b\u8bd5\u7248\u672c\uff08\u5df2\u4fee\u6b63\uff09", "force_update": true}
```

## Response `200`

```json
{"message":"version updated"}
```

## curl

```bash
curl -s -X PUT "http://127.0.0.1:9600/api/app/version?app_id=test_app&platform=windows&version=0.1.0"
  -H "Content-Type: application/json"
  -d '{"release_notes": "\u6d4b\u8bd5\u7248\u672c\uff08\u5df2\u4fee\u6b63\uff09", "force_update": true}'
```