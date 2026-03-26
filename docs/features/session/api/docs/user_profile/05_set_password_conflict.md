# POST /user/password

Set password again when already set.

## Parameters

```json
{"new_password":"another123"}
```

## Response `409`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/user/password" `
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc1MDAxNzI4LCJpYXQiOjE3NzQzOTY5Mjh9.uEp3FYIW6vtxDubYrF0S9z14sl60gEv6iUK0aW9yvDg" `
  -H "Content-Type: application/json" `
  -d "{\"new_password\":\"another123\"}"
```

> Returns 409 if password already exists.