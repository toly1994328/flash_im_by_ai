# POST /groups/33a71c87-efc8-414d-af0e-696879167e33/leave

普通成员退出群聊。退出后 is_deleted=true，刷新宫格头像 + 发送系统消息。

## Response `200`

```json
{"success":true}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/33a71c87-efc8-414d-af0e-696879167e33/leave"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0IiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.lOvvUV2mQ4Sl9MsLtcdaL79zfdWsYsI8g_8gzdfO71c"
```

> 退群后可被重新邀请（ON CONFLICT 恢复 is_deleted=false）。