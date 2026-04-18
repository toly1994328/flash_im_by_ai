# POST /groups

创建群聊。群主自动加入，自动生成宫格头像，自动初始化 group_info，自动发送系统消息。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | 是 | 群名称 |
| member_ids | int[] | 是 | 成员 ID 列表（不含群主，至少 2 人） |

```json
{"name": "\u6d4b\u8bd5\u7fa4\u804a", "member_ids": [2, 3, 4]}
```

## Response `200`

```json
{"avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111,identicon:碧螺春绿:867018","conv_type":1,"created_at":"2026-04-17T17:21:46.899432Z","id":"2b9db0d1-ec3e-4aab-a869-29898e3756af","name":"测试群聊","owner_id":1}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MDUxMzA2LCJpYXQiOjE3NzY0NDY1MDZ9.RnddDHuGfJO_OhSBvfI0r626elwvlXOR-DZWQhRlKrA"
  -H "Content-Type: application/json"
  -d '{"name": "\u6d4b\u8bd5\u7fa4\u804a", "member_ids": [2, 3, 4]}'
```