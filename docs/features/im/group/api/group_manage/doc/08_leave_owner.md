# POST /groups/33a71c87-efc8-414d-af0e-696879167e33/leave

群主不能退群，返回 400。群主必须先转让或解散。

## Response `400`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/33a71c87-efc8-414d-af0e-696879167e33/leave"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.5NMBPyBR3-3MvkmY1zDZQLvBUGdVhxW2wpm4Agg4pjE"
```

> 群主不能退群，避免群变成无主状态。