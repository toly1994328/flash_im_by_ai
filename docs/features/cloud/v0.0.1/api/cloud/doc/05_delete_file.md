# DELETE /api/storage/files/14

删除文件。ref_count 归零时物理删除并回收配额。

## Response `200`

```json
{"message":"文件已删除","freed_bytes":155,"new_used_bytes":86869373,"new_quota_bytes":104857600}
```

## curl

```bash
curl -s -X DELETE "http://127.0.0.1:9600/api/storage/files/14"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyMzU4NDAzLCJpYXQiOjE3ODE3NTM2MDN9.vdZwvanUGIXhwZNEwyBfUJAOTDZAgvAebegLh-FcduM"
```