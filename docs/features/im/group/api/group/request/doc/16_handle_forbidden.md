# POST /conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join-requests/0b9354bf-cab2-49cd-83eb-796dfec8a791/handle

非群主处理入群申请返回 403。

```json
{"approved": true}
```

## Response `403`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join-requests/0b9354bf-cab2-49cd-83eb-796dfec8a791/handle"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.sXdTFkC44wUgo-zrZ6FkInpSYaH_UVAraxVOZ9N4JD0"
  -H "Content-Type: application/json"
  -d '{"approved": true}'
```

> 只有 conversations.owner_id 可以审批。