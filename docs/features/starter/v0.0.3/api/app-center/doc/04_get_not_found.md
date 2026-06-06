# GET /api/app/version?app_id=1&platform=ios

查询不存在的版本记录，返回 404。

## Response `404`

```json
{"error":"no version found","status":404}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/app/version?app_id=1&platform=ios"
```

> 该平台暂未发布任何版本