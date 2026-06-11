# POST /user/password

为用户 C 设置密码（注销前置条件）。

```json
{"new_password": "delete123"}
```

## Response `200`

```json
{"message":"密码设置成功"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/user/password"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0IiwiZXhwIjoxNzgxNzM5MjA4LCJpYXQiOjE3ODExMzQ0MDh9.STe4bCQO2G0_1o8B0YmpUmJB-ZRHjrURWWSyJrDYjsI"
  -H "Content-Type: application/json"
  -d '{"new_password": "delete123"}'
```