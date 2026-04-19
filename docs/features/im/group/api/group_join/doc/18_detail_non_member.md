# GET /groups/1e011830-5353-48f7-ab89-a05c69faaaf5/detail

非群成员查看群详情返回 403。

## Response `403`

```json
(empty body)
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/groups/1e011830-5353-48f7-ab89-a05c69faaaf5/detail"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0IiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9.gfqTEqJWjfGndjcEEaquqwPKO63AYhmK5NaxgiQXnFY"
```

> 只有群成员可以查看群详情。