# PUT /groups/0756c679-62de-4f8f-a274-43d29187d18b

群主修改群名。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | 否 | 新群名 |
| avatar | string | 否 | 新群头像 URL |

```json
{"name": "\u65b0\u7fa4\u540d-\u7ba1\u7406\u6d4b\u8bd5"}
```

## Response `200`

```json
{"success":true}
```

## curl

```bash
curl -s -X PUT "http://127.0.0.1:9600/groups/0756c679-62de-4f8f-a274-43d29187d18b"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3NTA2ODU0LCJpYXQiOjE3NzY5MDIwNTR9.OvMfZ0nEOPIxrXAWzv7wrfR8YEUsQFQljufpASuRvOU"
  -H "Content-Type: application/json"
  -d '{"name": "\u65b0\u7fa4\u540d-\u7ba1\u7406\u6d4b\u8bd5"}'
```