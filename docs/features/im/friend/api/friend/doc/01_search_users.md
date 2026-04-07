# GET /api/users/search?keyword=橘

按昵称模糊搜索用户。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| keyword | string | 是 | 搜索关键词（昵称模糊匹配） |
| limit | int | 否 | 返回条数，默认 20，最大 50 |

## Response `200`

```json
{"data":[]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/users/search?keyword=橘"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2MTI3MjQ4LCJpYXQiOjE3NzU1MjI0NDh9.NOjzp1Fxet0WEQpJBHyW3lhFZ89dSQ0W4oPEsJzJfv4"
```