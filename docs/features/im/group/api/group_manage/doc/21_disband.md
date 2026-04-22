# POST /groups/9a8114f7-8766-4bf2-86ab-623a219257c7/disband

群主解散群聊。先发系统消息'群聊已解散'，再标记 status=1。不删除成员和消息。

## Response `200`

```json
{"success":true}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/9a8114f7-8766-4bf2-86ab-623a219257c7/disband"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.5NMBPyBR3-3MvkmY1zDZQLvBUGdVhxW2wpm4Agg4pjE"
```

> 解散顺序：先发系统消息（成员关系还在）→ 再 UPDATE status=1。