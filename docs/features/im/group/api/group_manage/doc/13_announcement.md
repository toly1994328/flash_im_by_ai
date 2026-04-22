# PUT /groups/33a71c87-efc8-414d-af0e-696879167e33/announcement

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
curl -s -X PUT "http://127.0.0.1:9600/groups/33a71c87-efc8-414d-af0e-696879167e33/announcement"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.5NMBPyBR3-3MvkmY1zDZQLvBUGdVhxW2wpm4Agg4pjE"
  -H "Content-Type: application/json"
  -d '{"announcement": "\u672c\u5468\u516d\u4e0b\u5348\u4e24\u70b9\u7ebf\u4e0b\u805a\u4f1a"}'
```