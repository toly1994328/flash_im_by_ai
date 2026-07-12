# POST /conversations/eb8cf7ec-44d8-4c38-a190-72bf3c878d81/mute

Toggle 免打扰状态（首次调用，关闭 → 开启）。

## Response `200`

```json
{"is_muted":true,"is_pinned":null,"unread_count":null}
```

> 每次调用翻转 is_muted，仅影响当前用户的会话通知。