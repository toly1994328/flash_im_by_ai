# GET /conversations/5692e36a-77a4-4054-85b0-a953097a92d5/messages/search?keyword=签到

在指定会话内搜索消息内容。返回匹配的消息列表（含 seq，可用于定位）。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| keyword | string | 是 | 搜索关键词 |
| limit | int | 否 | 返回条数，默认 50，最大 100 |

## Response `200`

```json
{"data":[{"content":"枫叶红签到 🍁","created_at":"2026-04-26T14:33:52.810223+00:00","message_id":"1a1d556b-875d-4e87-b956-3ef7a2d34cde","sender_avatar":"identicon:枫叶红:c21f30","sender_name":"枫叶红","seq":8},{"content":"姜黄签到，中药色系代表","created_at":"2026-04-26T14:33:52.616167+00:00","message_id":"0e89136a-31d0-4406-a96c-660f065c07a8","sender_avatar":"identicon:姜黄:d6c560","sender_name":"姜黄","seq":4}]}
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations/5692e36a-77a4-4054-85b0-a953097a92d5/messages/search?keyword=签到"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3ODE5ODgwLCJpYXQiOjE3NzcyMTUwODB9.G3K0pR5JybdqIG7bzZP6WloATsEl1_ujoxoX4pztqZA"
```