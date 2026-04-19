# GET /groups/search?keyword=验证

审批通过后，申请者搜索该群时 is_member=true，has_pending_request=false。

## Response `200`

```json
[{"id":"1e011830-5353-48f7-ab89-a05c69faaaf5","name":"验证群聊","avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111,identicon:天蓝:1677b3","owner_id":1,"group_no":10012,"member_count":4,"is_member":true,"join_verification":true,"has_pending_request":false}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/groups/search?keyword=验证"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1IiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9._yeyry_Gy62lFGahp-S5tLYYIzmsdp1LaPjtNnmoISM"
```

> 验证审批流程完整性：申请 → 审批通过 → 成为成员。