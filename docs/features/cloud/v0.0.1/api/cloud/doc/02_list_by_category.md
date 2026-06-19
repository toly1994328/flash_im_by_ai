# GET /api/storage/files?category=image

按类型筛选文件列表。

## Response `200`

```json
{"data":[{"id":13,"url":"/uploads/original/2026/06/ca5d61d5-5fe4-4b3c-87b1-2e880616e1b7.png","thumb_url":"/uploads/thumb/2026/06/ca5d61d5-5fe4-4b3c-87b1-2e880616e1b7.webp","size":74,"mime_type":"image/png","mime_category":"image","width":2,"height":2,"duration_ms":null,"ref_count":1,"created_at":"2026-06-18T03:33:23.212703Z"},{"id":8,"url":"/uploads/original/2026/06/0dffda5f-26ce-4f56-b792-f29c65e34223.jpg","thumb_url":"/uploads/thumb/2026/06/0dffda5f-26ce-4f56-b792-f29c65e34223.webp","size":402405,"mime_type":"image/jpg","mime_category":"image","width":1800,"height":4000,"duration_ms":null,"ref_count":1,"created_at":"2026-06-16T22:52:12.655766Z"},{"id":7,"url":"/uploads/original/2026/06/2dcfe978-0bc1-4b52-a10a-361fbb813eb0.jpg","thumb_url":"/uploads/thumb/2026/06/2dcfe978-0bc1-4b52-a10a-361fbb813eb0.webp","size":491767,"mime_type":"image/jpg","mime_category":"image","width":1080,"height":2400,"duration_ms":null,"ref_count":1,"created_at":"2026-06-16T22:51:34.402028Z"},{"id":6,"url":"/uploads/original/2026/06/08192cf9-a1bf-438e-9d22-c7e53b9db20a.jpg","thumb_url":"/uploads/thumb/2026/06/08192cf9-a1bf-438e-9d22-c7e53b9db20a.webp","size":896953,"mime_type":"image/jpg","mime_category":"image","width":2400,"height":1080,"duration_ms":null,"ref_count":1,"created_at":"2026-06-16T22:51:01.462058Z"},{"id":5,"url":"/uploads/original/2026/06/4f1b10f5-f352-4adc-bb6a-63ec7e1a946b.jpg","thumb_url":"/uploads/thumb/2026/06/4f1b10f5-f352-4adc-bb6a-63ec7e1a946b.webp","size":1578702,"mime_type":"image/jpg","mime_category":"image","width":1080,"height":2400,"duration_ms":null,"ref_count":1,"created_at":"2026-06-16T22:48:38.514751Z"}],"total":5,"page":1,"limit":20}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/storage/files?category=image"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyMzU4NDAzLCJpYXQiOjE3ODE3NTM2MDN9.vdZwvanUGIXhwZNEwyBfUJAOTDZAgvAebegLh-FcduM"
```

> 返回的所有项 mime_category 均为 image。