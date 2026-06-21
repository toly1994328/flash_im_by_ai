# POST /api/storage/upload-token

无订阅用户请求 upload-token 被拒绝（403）。

```json
{"file_name": "test.jpg", "file_size": 1024, "mime_type": "image/jpeg", "hash": "abc123"}
```

## Response `403`

```json
{"error":"需要订阅才能使用云存储上传","status":403}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/storage/upload-token"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyNjE2MzQzLCJpYXQiOjE3ODIwMTE1NDN9.hOIXWaFEm4WW3UP39oexFGwV-OKaNI9OBnVoA04fFdE"
  -H "Content-Type: application/json"
  -d '{"file_name": "test.jpg", "file_size": 1024, "mime_type": "image/jpeg", "hash": "abc123"}'
```

> 无活跃订阅的用户不能使用 OSS 上传