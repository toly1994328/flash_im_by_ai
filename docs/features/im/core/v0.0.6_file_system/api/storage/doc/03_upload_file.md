# POST /api/upload/file

上传通用文件。最大 50MB。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| file | file | 是 | 文件（multipart） |
| hash | string | 是 | 文件 SHA-1 hex |

## Response `200`

```json
{"file_id":10,"file_url":"/uploads/file/2026/06/f36a72ae-8b19-4192-bd18-0b0ec6940e88.txt","file_name":"test.txt","file_size":190,"file_type":"txt","is_dedup":false}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/upload/file"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgyMjUxOTg1LCJpYXQiOjE3ODE2NDcxODV9.rCbkWzYq8CjyLgp2MfgnxoG41jerLuK5X1RFUhJsWtg"
  -F "file=@C:\Users\19814\AppData\Local\Temp\tmplj9o99gf\test.txt"
  -F "hash=4e3a70572be19140d7962ac6e69980dd9b480f7f"
```