# POST /groups/0756c679-62de-4f8f-a274-43d29187d18b/members

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
curl -s -X POST "http://127.0.0.1:9600/groups/0756c679-62de-4f8f-a274-43d29187d18b/members"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3NTA2ODU0LCJpYXQiOjE3NzY5MDIwNTR9.OvMfZ0nEOPIxrXAWzv7wrfR8YEUsQFQljufpASuRvOU"
  -H "Content-Type: application/json"
  -d '{"member_ids": [4, 5]}'
```