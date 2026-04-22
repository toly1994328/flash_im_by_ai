# POST /groups

创建第二个群用于解散测试，避免破坏主测试群。

```json
{"name": "\u5f85\u89e3\u6563\u7fa4", "member_ids": [2, 3]}
```

## Response `200`

```json
{"avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111","conv_type":1,"created_at":"2026-04-20T23:45:12.476300Z","id":"9a8114f7-8766-4bf2-86ab-623a219257c7","name":"待解散群","owner_id":1}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.5NMBPyBR3-3MvkmY1zDZQLvBUGdVhxW2wpm4Agg4pjE"
  -H "Content-Type: application/json"
  -d '{"name": "\u5f85\u89e3\u6563\u7fa4", "member_ids": [2, 3]}'
```

> 解散操作不可逆（status=1），需要独立的群来测试。