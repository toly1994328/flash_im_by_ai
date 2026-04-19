# GET /groups/search?keyword=开放

已是群成员时搜索结果中 is_member=true。

## Response `200`

```json
[{"id":"5aaebb83-19e1-45e7-891c-3a2b2775a9ea","name":"开放群聊","avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111","owner_id":1,"group_no":10011,"member_count":3,"is_member":true,"join_verification":false,"has_pending_request":false}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/groups/search?keyword=开放"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9.MBxC1j8_7j8yAwmsb2EcLsive56tPI8HF0ZpWj4bmK0"
```

> 前端根据 is_member 显示'已加入'灰色标签。