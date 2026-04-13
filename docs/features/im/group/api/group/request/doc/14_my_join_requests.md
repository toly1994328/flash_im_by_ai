# GET /conversations/my-join-requests

查询当前用户作为群主的所有待处理入群申请（跨群聚合）。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| limit | int | 否 | 每页条数，默认 20 |
| offset | int | 否 | 偏移量，默认 0 |

## Response `200`

```json
[{"avatar":"identicon:6","conversation_id":"890056e8-8d10-4e40-82a8-a8810ff7374d","created_at":"2026-04-12T14:40:38.530639Z","group_name":"测试群聊","handled_by":null,"id":"0b9354bf-cab2-49cd-83eb-796dfec8a791","message":"请让我加入","nickname":"用户0006","status":0,"updated_at":"2026-04-12T14:40:38.530639Z","user_id":6}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations/my-join-requests"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.e2lTgvQvUYvq00t9MNlOiNh1Pc66a5qoJGf-fx_5rws"
```