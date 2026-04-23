# POST /groups

创建第二个群用于解散测试，避免破坏主测试群。

```json
{"name": "\u5f85\u89e3\u6563\u7fa4", "member_ids": [2, 3]}
```

## Response `200`

```json
{"avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111","conv_type":1,"created_at":"2026-04-22T23:54:16.107643Z","id":"c56ba95b-61c5-4fcb-ace6-ac501484037a","name":"待解散群","owner_id":1}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3NTA2ODU0LCJpYXQiOjE3NzY5MDIwNTR9.OvMfZ0nEOPIxrXAWzv7wrfR8YEUsQFQljufpASuRvOU"
  -H "Content-Type: application/json"
  -d '{"name": "\u5f85\u89e3\u6563\u7fa4", "member_ids": [2, 3]}'
```

> 解散操作不可逆（status=1），需要独立的群来测试。