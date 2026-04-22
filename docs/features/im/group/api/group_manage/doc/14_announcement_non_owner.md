# PUT /groups/33a71c87-efc8-414d-af0e-696879167e33/announcement

非群主发布公告返回 403。

```json
{"announcement": "\u6211\u4e0d\u662f\u7fa4\u4e3b"}
```

## Response `403`

```json
(empty body)
```

## curl

```bash
curl -s -X PUT "http://127.0.0.1:9600/groups/33a71c87-efc8-414d-af0e-696879167e33/announcement"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.7Z1nZxpxZB41Zqe86nTUYAaYCJi5kWWiSRTNOrFNzvY"
  -H "Content-Type: application/json"
  -d '{"announcement": "\u6211\u4e0d\u662f\u7fa4\u4e3b"}'
```

> 只有群主可以发布/编辑群公告。