# GET /user/profile

注销后旧 token 失效验证。

## Response `404`

```json
(empty body)
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/user/profile"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0IiwiZXhwIjoxNzgxNzM5MjA4LCJpYXQiOjE3ODExMzQ0MDh9.STe4bCQO2G0_1o8B0YmpUmJB-ZRHjrURWWSyJrDYjsI"
```

> 注销后旧 token 应无法访问资源