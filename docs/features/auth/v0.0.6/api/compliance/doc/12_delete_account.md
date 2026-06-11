# POST /api/account/delete

注销账号。验证密码后直接删除用户数据。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| password | string | 是 | 用户密码 |

```json
{"password": "delete123"}
```

## Response `200`

```json
{"message":"注销成功"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/api/account/delete"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0IiwiZXhwIjoxNzgxNzM5MjA4LCJpYXQiOjE3ODExMzQ0MDh9.STe4bCQO2G0_1o8B0YmpUmJB-ZRHjrURWWSyJrDYjsI"
  -H "Content-Type: application/json"
  -d '{"password": "delete123"}'
```