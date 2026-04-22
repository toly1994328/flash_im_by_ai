# PUT /groups/33a71c87-efc8-414d-af0e-696879167e33/transfer

群主转让。owner_id 更新为新群主，发送系统消息。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| new_owner_id | i64 | 是 | 新群主的 user_id（必须是群成员） |

```json
{"new_owner_id": 2}
```

## Response `200`

```json
{"success":true}
```

## curl

```bash
curl -s -X PUT "http://127.0.0.1:9600/groups/33a71c87-efc8-414d-af0e-696879167e33/transfer"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.5NMBPyBR3-3MvkmY1zDZQLvBUGdVhxW2wpm4Agg4pjE"
  -H "Content-Type: application/json"
  -d '{"new_owner_id": 2}'
```