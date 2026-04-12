# GET /api/users/search?keyword=橘

搜索用户（支持昵称模糊、手机号精确、闪讯号精确三种匹配）。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| keyword | string | 是 | 搜索关键词（昵称模糊 / 手机号精确 / 闪讯号精确） |
| limit | int | 否 | 返回条数，默认 20，最大 50 |

## Response `200`

```json
{"data":[{"avatar":"identicon:橘橙:f97d1c","id":"2","nickname":"橘橙"}]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/users/search?keyword=橘"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NTkzOTcxLCJpYXQiOjE3NzU5ODkxNzF9.zS0yoOjS3x0n-SO_8A6zqWxQ3MVfFKqmBR3Gzav0T5Q"
```