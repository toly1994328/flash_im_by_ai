# DELETE /groups/0756c679-62de-4f8f-a274-43d29187d18b/members/5

非群主踢人返回 403。

## Response `403`

```json
(empty body)
```

## curl

```bash
curl -s -X DELETE "http://127.0.0.1:9600/groups/0756c679-62de-4f8f-a274-43d29187d18b/members/5"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc3NTA2ODU1LCJpYXQiOjE3NzY5MDIwNTV9.aSX1haVYCWshpi-kSMQipO4ftHQnprzE1Y6FSs6YpGE"
```

> 只有群主可以踢人。