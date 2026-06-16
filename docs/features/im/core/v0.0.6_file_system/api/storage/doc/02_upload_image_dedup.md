# POST /api/upload/image

重复上传相同文件（秒传）。服务端检测到相同 hash，不重复存储，直接返回已有记录。

## Response `200`

```json
{"file_id":9,"original_url":"/uploads/original/2026/06/cf8c75aa-cd6c-48e3-a144-653ab55a1940.png","thumbnail_url":"/uploads/thumb/2026/06/cf8c75aa-cd6c-48e3-a144-653ab55a1940.webp","width":1,"height":1,"size":69,"format":"png","is_dedup":true}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/upload/image"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyMjUxOTg1LCJpYXQiOjE3ODE2NDcxODV9.rCbkWzYq8CjyLgp2MfgnxoG41jerLuK5X1RFUhJsWtg"
  -F "file=@C:\Users\19814\AppData\Local\Temp\tmplj9o99gf\test.png"
  -F "hash=2732f12a8f18d27cf0fa78ef41091bfa1ccec9ce"
```

> is_dedup=true 表示秒传，未写入新文件。