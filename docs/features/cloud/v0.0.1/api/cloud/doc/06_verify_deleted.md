# GET /api/storage/files?category=file

验证已删除的文件不再出现在列表中。

## Response `200`

```json
{"data":[{"id":12,"url":"/uploads/file/2026/06/a3fbf1f0-356a-4b34-94fd-e76e570da7e6.mp4","thumb_url":null,"size":27747674,"mime_type":"application/octet-stream","mime_category":"file","width":null,"height":null,"duration_ms":null,"ref_count":1,"created_at":"2026-06-16T23:18:34.238450Z"},{"id":11,"url":"/uploads/file/2026/06/4f8f36c2-06c5-486c-9552-de9d0282d665.mp4","thumb_url":null,"size":10987942,"mime_type":"application/octet-stream","mime_category":"file","width":null,"height":null,"duration_ms":null,"ref_count":1,"created_at":"2026-06-16T22:55:17.803657Z"},{"id":10,"url":"/uploads/file/2026/06/925cc12f-f3ed-44fa-97dd-893b8a891c21.pdf","thumb_url":null,"size":525986,"mime_type":"application/pdf","mime_category":"file","width":null,"height":null,"duration_ms":null,"ref_count":1,"created_at":"2026-06-16T22:54:33.802784Z"}],"total":3,"page":1,"limit":20}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/storage/files?category=file"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyMzU4NDAzLCJpYXQiOjE3ODE3NTM2MDN9.vdZwvanUGIXhwZNEwyBfUJAOTDZAgvAebegLh-FcduM"
```

> 删除后文件从列表消失。