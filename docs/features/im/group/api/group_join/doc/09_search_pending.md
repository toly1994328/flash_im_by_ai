# GET /groups/search?keyword=验证

有待处理申请时搜索结果中 has_pending_request=true。

## Response `200`

```json
[{"id":"1e011830-5353-48f7-ab89-a05c69faaaf5","name":"验证群聊","avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111","owner_id":1,"group_no":10012,"member_count":3,"is_member":false,"join_verification":true,"has_pending_request":true}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/groups/search?keyword=验证"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1IiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9._yeyry_Gy62lFGahp-S5tLYYIzmsdp1LaPjtNnmoISM"
```

> 前端根据 has_pending_request 显示'已申请'灰色标签。