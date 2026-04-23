# PUT /groups/0756c679-62de-4f8f-a274-43d29187d18b/announcement

群主发布/编辑群公告。更新 group_info 的 announcement 字段。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| announcement | string | 是 | 群公告内容 |

```json
{"announcement": "\u672c\u5468\u516d\u4e0b\u5348\u4e24\u70b9\u7ebf\u4e0b\u805a\u4f1a"}
```

## Response `200`

```json
{"success":true}
```

## curl

```bash
curl -s -X PUT "http://127.0.0.1:9600/groups/0756c679-62de-4f8f-a274-43d29187d18b/announcement"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3NTA2ODU0LCJpYXQiOjE3NzY5MDIwNTR9.OvMfZ0nEOPIxrXAWzv7wrfR8YEUsQFQljufpASuRvOU"
  -H "Content-Type: application/json"
  -d '{"announcement": "\u672c\u5468\u516d\u4e0b\u5348\u4e24\u70b9\u7ebf\u4e0b\u805a\u4f1a"}'
```