# GET /api/storage/files/99999

查询不存在的文件，返回 404。

## Response `404`

```json
{"error":"文件不存在","status":404}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/storage/files/99999"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyMzU4NDAzLCJpYXQiOjE3ODE3NTM2MDN9.vdZwvanUGIXhwZNEwyBfUJAOTDZAgvAebegLh-FcduM"
```

> 文件不存在或不属于当前用户时返回 404。