# PUT /groups/33a71c87-efc8-414d-af0e-696879167e33

群名为空返回 400。

```json
{"name": ""}
```

## Response `400`

```json
(empty body)
```

## curl

```bash
curl -s -X PUT "http://127.0.0.1:9600/groups/33a71c87-efc8-414d-af0e-696879167e33"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.5NMBPyBR3-3MvkmY1zDZQLvBUGdVhxW2wpm4Agg4pjE"
  -H "Content-Type: application/json"
  -d '{"name": ""}'
```

> 群名不能为空字符串。