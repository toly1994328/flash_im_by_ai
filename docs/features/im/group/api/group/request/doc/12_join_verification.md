# POST /conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join

入群申请（需验证时创建申请记录，WS 通知群主）。

```json
{"message": "\u8bf7\u8ba9\u6211\u52a0\u5165"}
```

## Response `200`

```json
{"auto_approved":false,"group_name":"测试群聊","owner_id":"1"}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI2IiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.BHrZAJFXQwsv5_WPSVaTWUCoeOm2VqavuaZw4j1_Wyk"
  -H "Content-Type: application/json"
  -d '{"message": "\u8bf7\u8ba9\u6211\u52a0\u5165"}'
```

> group_info.join_verification=true 时，不直接加入，而是创建 group_join_requests 记录。