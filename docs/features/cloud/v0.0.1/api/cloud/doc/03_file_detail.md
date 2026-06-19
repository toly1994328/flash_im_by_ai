# GET /api/storage/files/13

查询文件详情，含引用的会话列表。

## Response `200`

```json
{"file":{"id":13,"url":"/uploads/original/2026/06/ca5d61d5-5fe4-4b3c-87b1-2e880616e1b7.png","thumb_url":"/uploads/thumb/2026/06/ca5d61d5-5fe4-4b3c-87b1-2e880616e1b7.webp","size":74,"mime_type":"image/png","mime_category":"image","width":2,"height":2,"duration_ms":null,"ref_count":1,"created_at":"2026-06-18T03:33:23.212703Z"},"conversations":[]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/storage/files/13"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyMzU4NDAzLCJpYXQiOjE3ODE3NTM2MDN9.vdZwvanUGIXhwZNEwyBfUJAOTDZAgvAebegLh-FcduM"
```