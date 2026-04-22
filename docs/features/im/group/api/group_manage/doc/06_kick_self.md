# DELETE /groups/33a71c87-efc8-414d-af0e-696879167e33/members/1

群主不能踢自己，返回 400。群主需要先转让或解散群聊。

## Response `400`

```json
(empty body)
```

## curl

```bash
curl -s -X DELETE "http://127.0.0.1:9600/groups/33a71c87-efc8-414d-af0e-696879167e33/members/1"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.5NMBPyBR3-3MvkmY1zDZQLvBUGdVhxW2wpm4Agg4pjE"
```

> 群主不能踢自己，避免群变成无主状态。