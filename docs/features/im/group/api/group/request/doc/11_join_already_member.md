# POST /conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join

已是群成员时返回 400。

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
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1IiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.FxUIKIlIdqtyFc4P5kDfknBjLBvyge9I2js_Z5Wr7xg"
  -H "Content-Type: application/json"
  -d '{}'
```

> 防止重复加入。