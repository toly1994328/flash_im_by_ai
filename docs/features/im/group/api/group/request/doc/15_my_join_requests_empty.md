# GET /conversations/my-join-requests

非群主查询返回空列表。

## Response `200`

```json
[]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations/my-join-requests"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.sXdTFkC44wUgo-zrZ6FkInpSYaH_UVAraxVOZ9N4JD0"
```

> 只返回当前用户作为 owner_id 的群的待处理申请。