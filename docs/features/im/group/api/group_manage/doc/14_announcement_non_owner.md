# PUT /groups/0756c679-62de-4f8f-a274-43d29187d18b/announcement

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
curl -s -X PUT "http://127.0.0.1:9600/groups/0756c679-62de-4f8f-a274-43d29187d18b/announcement"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc3NTA2ODU1LCJpYXQiOjE3NzY5MDIwNTV9.aSX1haVYCWshpi-kSMQipO4ftHQnprzE1Y6FSs6YpGE"
  -H "Content-Type: application/json"
  -d '{"announcement": "\u6211\u4e0d\u662f\u7fa4\u4e3b"}'
```

> 只有群主可以发布/编辑群公告。