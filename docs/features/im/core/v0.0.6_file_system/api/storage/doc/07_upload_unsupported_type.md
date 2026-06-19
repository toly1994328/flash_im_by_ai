# POST /api/upload/image

上传不支持的图片格式（如 .bmp）。返回 400。

## Response `400`

```json
{"code":"UNSUPPORTED_TYPE","message":"文件类型不支持: bmp"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/upload/image"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyMjUxOTg1LCJpYXQiOjE3ODE2NDcxODV9.rCbkWzYq8CjyLgp2MfgnxoG41jerLuK5X1RFUhJsWtg"
  -F "file=@C:\Users\19814\AppData\Local\Temp\tmplj9o99gf\test.bmp"
  -F "hash=176f6daa7a70c7a1e1d45c263b72588f935d6617"
```

> 图片只支持 jpg/png/gif/webp。