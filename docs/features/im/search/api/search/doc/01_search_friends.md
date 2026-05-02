# GET /api/friends/search?keyword=橘

搜索当前用户的好友，按昵称模糊匹配。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| keyword | string | 是 | 搜索关键词（昵称模糊匹配） |
| limit | int | 否 | 返回条数，默认 20，最大 50 |

## Response `200`

```json
{"data":[{"avatar":"identicon:橘橙:f97d1c","friend_id":"2","nickname":"橘橙"}]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/friends/search?keyword=橘"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc4MzcwNDk3LCJpYXQiOjE3Nzc3NjU2OTd9.3woan6cwSZSYb0105mBe1_EocZxGU8-yquq11g8W7ak"
```