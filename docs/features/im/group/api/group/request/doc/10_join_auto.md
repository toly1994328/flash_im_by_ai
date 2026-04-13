# POST /conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join

入群申请（无需验证时直接加入）。group_info.join_verification 默认 false。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| message | string | 否 | 申请留言 |

```json
{"message": "\u6211\u60f3\u52a0\u5165"}
```

## Response `200`

```json
{"auto_approved":true,"group_name":null,"owner_id":null}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1IiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.FxUIKIlIdqtyFc4P5kDfknBjLBvyge9I2js_Z5Wr7xg"
  -H "Content-Type: application/json"
  -d '{"message": "\u6211\u60f3\u52a0\u5165"}'
```