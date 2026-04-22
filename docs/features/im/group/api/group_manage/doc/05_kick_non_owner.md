# DELETE /groups/33a71c87-efc8-414d-af0e-696879167e33/members/5

非群主踢人返回 403。

## Response `403`

```json
(empty body)
```

## curl

```bash
curl -s -X DELETE "http://127.0.0.1:9600/groups/33a71c87-efc8-414d-af0e-696879167e33/members/5"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.7Z1nZxpxZB41Zqe86nTUYAaYCJi5kWWiSRTNOrFNzvY"
```

> 只有群主可以踢人。