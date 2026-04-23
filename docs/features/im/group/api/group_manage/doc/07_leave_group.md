# POST /groups/0756c679-62de-4f8f-a274-43d29187d18b/leave

普通成员退出群聊。退出后 is_deleted=true，刷新宫格头像 + 发送系统消息。

## Response `200`

```json
{"success":true}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/0756c679-62de-4f8f-a274-43d29187d18b/leave"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0IiwiZXhwIjoxNzc3NTA2ODU1LCJpYXQiOjE3NzY5MDIwNTV9.yjUAh0hgyFLvPzAMtRKMadrfVkse-6JGtSbVdGkdVc4"
```

> 退群后可被重新邀请（ON CONFLICT 恢复 is_deleted=false）。