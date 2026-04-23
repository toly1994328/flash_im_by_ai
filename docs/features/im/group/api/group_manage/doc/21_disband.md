# POST /groups/c56ba95b-61c5-4fcb-ace6-ac501484037a/disband

群主解散群聊。先发系统消息'群聊已解散'，再标记 status=1。不删除成员和消息。

## Response `200`

```json
{"success":true}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/c56ba95b-61c5-4fcb-ace6-ac501484037a/disband"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3NTA2ODU0LCJpYXQiOjE3NzY5MDIwNTR9.OvMfZ0nEOPIxrXAWzv7wrfR8YEUsQFQljufpASuRvOU"
```

> 解散顺序：先发系统消息（成员关系还在）→ 再 UPDATE status=1。