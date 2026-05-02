# GET /api/conversations/search-joined-groups?keyword=七彩

搜索当前用户已加入的群聊，按群名模糊匹配。只返回已加入且未解散的群。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| keyword | string | 是 | 搜索关键词（群名模糊匹配） |
| limit | int | 否 | 返回条数，默认 20，最大 50 |

## Response `200`

```json
{"data":[{"avatar":"grid:identicon:朱红:ed5126,identicon:橘橙:f97d1c,identicon:藤黄:ffd111,identicon:碧螺春绿:867018,identicon:天蓝:1677b3,identicon:景泰蓝:2775b6,identicon:葡萄紫:4c1f24","conversation_id":"4da5fa4d-5309-4c16-812a-7035e9990a03","member_count":7,"name":"七彩虹"}]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/conversations/search-joined-groups?keyword=七彩"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc4MzcwNDk3LCJpYXQiOjE3Nzc3NjU2OTd9.3woan6cwSZSYb0105mBe1_EocZxGU8-yquq11g8W7ak"
```