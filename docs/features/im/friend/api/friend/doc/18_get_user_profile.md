# GET /api/users/2

获取用户公开资料（昵称、头像、签名）。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | int | 是 | 用户 ID（路径参数） |

## Response `200`

```json
{"data":{"avatar":"identicon:橘橙:f97d1c","id":"2","nickname":"橘橙","signature":"温暖明亮，橙色系代表"}}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/users/2"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NTkzOTcxLCJpYXQiOjE3NzU5ODkxNzF9.zS0yoOjS3x0n-SO_8A6zqWxQ3MVfFKqmBR3Gzav0T5Q"
```