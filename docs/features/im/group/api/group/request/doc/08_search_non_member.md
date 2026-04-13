# GET /conversations/search

非成员搜索同一群聊，is_member=false。

## Response `200`

```json
[{"avatar":"grid:identicon:1,identicon:2,identicon:3,identicon:4","id":"890056e8-8d10-4e40-82a8-a8810ff7374d","is_member":false,"join_verification":false,"member_count":4,"name":"测试群聊"}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations/search"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI2IiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.BHrZAJFXQwsv5_WPSVaTWUCoeOm2VqavuaZw4j1_Wyk"
```

> 用于前端判断显示「加入」还是「已加入」按钮。