# POST /groups/9a8114f7-8766-4bf2-86ab-623a219257c7/disband

非群主解散群聊返回 403。

## Response `403`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/9a8114f7-8766-4bf2-86ab-623a219257c7/disband"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.7Z1nZxpxZB41Zqe86nTUYAaYCJi5kWWiSRTNOrFNzvY"
```

> 只有群主可以解散群聊。