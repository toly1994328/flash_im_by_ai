# PUT /user/password

Change password with wrong old password.

## Parameters

```json
{"old_password":"wrong","new_password":"whatever123"}
```

## Response `401`

```json
(empty body)
```

## curl

```bash
curl -s -X PUT "http://127.0.0.1:9600/user/password" `
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc1MDAxNzI4LCJpYXQiOjE3NzQzOTY5Mjh9.uEp3FYIW6vtxDubYrF0S9z14sl60gEv6iUK0aW9yvDg" `
  -H "Content-Type: application/json" `
  -d "{\"old_password\":\"wrong\",\"new_password\":\"whatever123\"}"
```

> Returns 401 if old password is incorrect.