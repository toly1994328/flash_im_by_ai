# POST /groups/c56ba95b-61c5-4fcb-ace6-ac501484037a/disband

非群主解散群聊返回 403。

## Response `403`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/c56ba95b-61c5-4fcb-ace6-ac501484037a/disband"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc3NTA2ODU1LCJpYXQiOjE3NzY5MDIwNTV9.aSX1haVYCWshpi-kSMQipO4ftHQnprzE1Y6FSs6YpGE"
```

> 只有群主可以解散群聊。