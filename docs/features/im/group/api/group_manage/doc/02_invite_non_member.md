# POST /groups/33a71c87-efc8-414d-af0e-696879167e33/members

非群成员邀请他人入群返回 403。

```json
{"member_ids": [6]}
```

## Response `403`

```json
{"error":"非群成员，无权邀请","status":403}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/33a71c87-efc8-414d-af0e-696879167e33/members"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI2IiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.4uOua7ci4XLTjg9UmJDAj4mLfdG6TDRE-VHXNhcxarc"
  -H "Content-Type: application/json"
  -d '{"member_ids": [6]}'
```

> 只有群成员才能邀请新成员。