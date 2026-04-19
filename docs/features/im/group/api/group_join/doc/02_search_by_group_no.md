# GET /groups/search?keyword=10011

按群号精确搜索群聊。keyword 为纯数字时走群号匹配。

## Response `200`

```json
[{"id":"5aaebb83-19e1-45e7-891c-3a2b2775a9ea","name":"开放群聊","avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111","owner_id":1,"group_no":10011,"member_count":3,"is_member":false,"join_verification":false,"has_pending_request":false}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/groups/search?keyword=10011"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0IiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9.gfqTEqJWjfGndjcEEaquqwPKO63AYhmK5NaxgiQXnFY"
```

> 纯数字 keyword 按 group_no 精确匹配，非数字按群名 ILIKE 模糊搜索。