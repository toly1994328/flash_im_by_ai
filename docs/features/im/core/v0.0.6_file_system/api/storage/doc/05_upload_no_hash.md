# POST /api/upload/image

上传图片但缺少 hash 字段。返回 400。

## Response `400`

```json
{"code":"BAD_REQUEST","message":"缺少 hash"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/upload/image"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyMjUxOTg1LCJpYXQiOjE3ODE2NDcxODV9.rCbkWzYq8CjyLgp2MfgnxoG41jerLuK5X1RFUhJsWtg"
  -F "file=@C:\Users\19814\AppData\Local\Temp\tmplj9o99gf\test.png"
```

> 缺少 hash 字段时返回 400 BAD_REQUEST。