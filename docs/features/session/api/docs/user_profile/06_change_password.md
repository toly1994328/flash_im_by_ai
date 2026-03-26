# PUT /user/password

Change password. Requires old password verification.

## Parameters

```json
{"old_password":"test123456","new_password":"newpass789"}
```

## Response `200`

```json
{"message":"密码修改成功"}
```

## curl

```bash
curl -s -X PUT "http://127.0.0.1:9600/user/password" `
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc1MDAxNzI4LCJpYXQiOjE3NzQzOTY5Mjh9.uEp3FYIW6vtxDubYrF0S9z14sl60gEv6iUK0aW9yvDg" `
  -H "Content-Type: application/json" `
  -d "{\"old_password\":\"test123456\",\"new_password\":\"newpass789\"}"
```