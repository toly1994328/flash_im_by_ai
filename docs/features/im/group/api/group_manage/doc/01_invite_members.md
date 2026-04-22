# POST /groups/33a71c87-efc8-414d-af0e-696879167e33/members

邀请新成员入群。群成员可邀请，直接加入不走审批。刷新宫格头像 + 发送系统消息。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| member_ids | array<i64> | 是 | 要邀请的用户 ID 列表 |

```json
{"member_ids": [4, 5]}
```

## Response `200`

```json
{"added_count":2,"success":true}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/33a71c87-efc8-414d-af0e-696879167e33/members"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.5NMBPyBR3-3MvkmY1zDZQLvBUGdVhxW2wpm4Agg4pjE"
  -H "Content-Type: application/json"
  -d '{"member_ids": [4, 5]}'
```