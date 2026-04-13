# POST /conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join-requests/0b9354bf-cab2-49cd-83eb-796dfec8a791/handle

群主同意入群申请。副作用：申请者加入群聊 + 刷新宫格头像。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| approved | bool | 是 | true=同意, false=拒绝 |

```json
{"approved": true}
```

## Response `200`

```json
{"data":null}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/conversations/890056e8-8d10-4e40-82a8-a8810ff7374d/join-requests/0b9354bf-cab2-49cd-83eb-796dfec8a791/handle"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NjA5NjM3LCJpYXQiOjE3NzYwMDQ4Mzd9.e2lTgvQvUYvq00t9MNlOiNh1Pc66a5qoJGf-fx_5rws"
  -H "Content-Type: application/json"
  -d '{"approved": true}'
```