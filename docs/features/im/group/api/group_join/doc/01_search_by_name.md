# GET /groups/search?keyword=开放

按群名模糊搜索群聊。返回成员数、是否已加入、是否需验证、是否已申请。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| keyword | string | 是 | 搜索关键词（≥2 字符，纯数字按群号精确匹配，否则按群名模糊搜索） |

## Response `200`

```json
[{"id":"5aaebb83-19e1-45e7-891c-3a2b2775a9ea","name":"开放群聊","avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111","owner_id":1,"group_no":10011,"member_count":3,"is_member":false,"join_verification":false,"has_pending_request":false}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/groups/search?keyword=开放"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0IiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9.gfqTEqJWjfGndjcEEaquqwPKO63AYhmK5NaxgiQXnFY"
```