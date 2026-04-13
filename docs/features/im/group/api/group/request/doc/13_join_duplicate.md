# POST /conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join

已有待处理申请时返回 400。

```json
{}
```

## Response `400`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI2IiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.BHrZAJFXQwsv5_WPSVaTWUCoeOm2VqavuaZw4j1_Wyk"
  -H "Content-Type: application/json"
  -d '{}'
```

> 同一用户对同一群只能有一条 pending 申请。