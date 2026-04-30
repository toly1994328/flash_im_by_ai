# GET /conversations/294588ba-f96e-4ced-9d7c-b73bd6f66117/messages?before_seq=1&limit=3

向上翻页：返回 seq < before_seq 的消息，按 seq DESC 排序。行为不变。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| before_seq | int | 否 | 返回 seq 小于此值的消息 |
| limit | int | 否 | 返回条数 |

## Response `200`

```json
[]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations/294588ba-f96e-4ced-9d7c-b73bd6f66117/messages?before_seq=1&limit=3"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc4MDIzMjY1LCJpYXQiOjE3Nzc0MTg0NjV9.RhIIUK4RoFV_1o84WPRFu6l_CR53CFjGK3v-ftBpwE0"
```