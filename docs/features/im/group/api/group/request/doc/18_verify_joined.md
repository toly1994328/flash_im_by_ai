# GET /conversations/search

审批通过后，申请者搜索该群时 is_member=true。

## Response `200`

```json
[{"avatar":"grid:identicon:1,identicon:2,identicon:3,identicon:4,identicon:5,identicon:6","id":"890056e8-8d10-4e40-82a8-a8810ff7374d","is_member":true,"join_verification":true,"member_count":6,"name":"测试群聊"}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations/search"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI2IiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.BHrZAJFXQwsv5_WPSVaTWUCoeOm2VqavuaZw4j1_Wyk"
```

> 验证 handle_join_request 的 add_member 副作用。