# POST /groups/5aaebb83-19e1-45e7-891c-3a2b2775a9ea/join

入群（无需验证）：直接加入成功，返回 auto_approved=true。自动刷新宫格头像并发送系统消息。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| message | string | 否 | 申请留言（无需验证时忽略） |

```json
{"message": "\u6211\u60f3\u52a0\u5165"}
```

## Response `200`

```json
{"auto_approved":true}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/5aaebb83-19e1-45e7-891c-3a2b2775a9ea/join"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0IiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9.gfqTEqJWjfGndjcEEaquqwPKO63AYhmK5NaxgiQXnFY"
  -H "Content-Type: application/json"
  -d '{"message": "\u6211\u60f3\u52a0\u5165"}'
```