# POST /groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join

被拒绝后可以重新申请入群。

```json
{"message": "\u6211\u4e5f\u60f3\u52a0\u5165"}
```

## Response `200`

```json
{"auto_approved":false}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0IiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9.gfqTEqJWjfGndjcEEaquqwPKO63AYhmK5NaxgiQXnFY"
  -H "Content-Type: application/json"
  -d '{"message": "\u6211\u4e5f\u60f3\u52a0\u5165"}'
```

> 被拒绝的申请 status=2，不阻止新的 status=0 申请。