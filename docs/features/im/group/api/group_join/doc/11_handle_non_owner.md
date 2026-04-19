# POST /groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join-requests/39f4f4a5-f6d6-40a8-998d-003a55094e0f/handle

非群主审批返回 403。

```json
{"approved": true}
```

## Response `403`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join-requests/39f4f4a5-f6d6-40a8-998d-003a55094e0f/handle"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9.MBxC1j8_7j8yAwmsb2EcLsive56tPI8HF0ZpWj4bmK0"
  -H "Content-Type: application/json"
  -d '{"approved": true}'
```

> 只有群主可以处理入群申请。