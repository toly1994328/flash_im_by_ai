# GET /conversations/search

按群名模糊搜索群聊，返回成员数、是否已加入、是否需要入群验证。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| keyword | string | 是 | 搜索关键词（群名模糊匹配） |
| limit | int | 否 | 返回条数，默认 20 |

## Response `200`

```json
[{"avatar":"grid:identicon:1,identicon:2,identicon:3,identicon:4","id":"890056e8-8d10-4e40-82a8-a8810ff7374d","is_member":true,"join_verification":false,"member_count":4,"name":"测试群聊"}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations/search"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.e2lTgvQvUYvq00t9MNlOiNh1Pc66a5qoJGf-fx_5rws"
```