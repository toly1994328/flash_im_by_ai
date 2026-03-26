# POST /auth/login

Login with password.

## Parameters

```json
{"phone":"13800001111","type":"password","credential":"newpass789"}
```

## Response `200`

```json
{"token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc1MDAxNzMwLCJpYXQiOjE3NzQzOTY5MzB9.iIbWrosu6vQdO1craVDWQYRRpfYhookhzc7F5nGX6NA","user_id":1,"has_password":true}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/auth/login" `
  -H "Content-Type: application/json" `
  -d "{\"phone\":\"13800001111\",\"type\":\"password\",\"credential\":\"newpass789\"}"
```