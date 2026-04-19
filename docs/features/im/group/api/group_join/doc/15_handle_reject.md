# POST /groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join-requests/0c5353ef-f40c-49ba-a5fc-e63dd29e6a66/handle

群主拒绝入群申请。申请状态变为 2（已拒绝），申请者不加入群聊。

```json
{"approved": false}
```

## Response `200`

```json
{"success":true}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join-requests/0c5353ef-f40c-49ba-a5fc-e63dd29e6a66/handle"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9.bkyRhLQ92eyB0vtIv1jP5wvukqHFuP4pNzpFHVO0-0U"
  -H "Content-Type: application/json"
  -d '{"approved": false}'
```

> 拒绝后申请者可以重新申请。