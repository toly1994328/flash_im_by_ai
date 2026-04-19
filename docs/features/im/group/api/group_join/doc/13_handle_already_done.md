# POST /groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join-requests/39f4f4a5-f6d6-40a8-998d-003a55094e0f/handle

已处理的申请再次审批返回 400。

```json
{"approved": true}
```

## Response `400`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join-requests/39f4f4a5-f6d6-40a8-998d-003a55094e0f/handle"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9.bkyRhLQ92eyB0vtIv1jP5wvukqHFuP4pNzpFHVO0-0U"
  -H "Content-Type: application/json"
  -d '{"approved": true}'
```

> status != 0 的申请不能再次处理。