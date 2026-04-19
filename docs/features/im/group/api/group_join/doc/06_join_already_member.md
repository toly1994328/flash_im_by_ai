# POST /groups/5aaebb83-19e1-45e7-891c-3a2b2775a9ea/join

已是群成员时再次入群返回 400。

```json
{"message": "\u6211\u60f3\u52a0\u5165"}
```

## Response `400`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/5aaebb83-19e1-45e7-891c-3a2b2775a9ea/join"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0IiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9.gfqTEqJWjfGndjcEEaquqwPKO63AYhmK5NaxgiQXnFY"
  -H "Content-Type: application/json"
  -d '{"message": "\u6211\u60f3\u52a0\u5165"}'
```

> 已加入的用户不能重复加入。