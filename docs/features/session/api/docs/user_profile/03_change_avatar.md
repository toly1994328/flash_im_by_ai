# PUT /user/profile

Change identicon avatar seed.

## Parameters

```json
{"avatar":"identicon:seed_42"}
```

## Response `200`

```json
{"user_id":1,"phone":"13800001111","nickname":"TestUser","avatar":"identicon:seed_42","signature":"hello world"}
```

## curl

```bash
curl -s -X PUT "http://127.0.0.1:9600/user/profile" `
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc1MDAxNzI4LCJpYXQiOjE3NzQzOTY5Mjh9.uEp3FYIW6vtxDubYrF0S9z14sl60gEv6iUK0aW9yvDg" `
  -H "Content-Type: application/json" `
  -d "{\"avatar\":\"identicon:seed_42\"}"
```