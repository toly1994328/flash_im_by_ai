# POST /groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join-requests/39f4f4a5-f6d6-40a8-998d-003a55094e0f/handle

群主同意入群申请。申请者自动加入群聊，刷新宫格头像，发送系统消息。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| approved | bool | 是 | true=同意, false=拒绝 |

```json
{"approved": true}
```

## Response `200`

```json
{"success":true}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join-requests/39f4f4a5-f6d6-40a8-998d-003a55094e0f/handle"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9.bkyRhLQ92eyB0vtIv1jP5wvukqHFuP4pNzpFHVO0-0U"
  -H "Content-Type: application/json"
  -d '{"approved": true}'
```