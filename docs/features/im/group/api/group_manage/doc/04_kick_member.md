# DELETE /groups/33a71c87-efc8-414d-af0e-696879167e33/members/5

群主踢人。被踢成员的 is_deleted 标记为 true，刷新宫格头像 + 发送系统消息。

## Response `200`

```json
{"success":true}
```

## curl

```bash
curl -s -X DELETE "http://127.0.0.1:9600/groups/33a71c87-efc8-414d-af0e-696879167e33/members/5"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.5NMBPyBR3-3MvkmY1zDZQLvBUGdVhxW2wpm4Agg4pjE"
```

> 只有群主可以踢人。