# POST /api/upload/image

未登录时上传文件。返回 401。

## Response `401`

```json
{"code":"UNAUTHORIZED","message":"未登录"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/upload/image"
  -F "file=@C:\Users\19814\AppData\Local\Temp\tmplj9o99gf\test.png"
  -F "hash=2732f12a8f18d27cf0fa78ef41091bfa1ccec9ce"
```

> 未携带 Authorization header 时返回 401。