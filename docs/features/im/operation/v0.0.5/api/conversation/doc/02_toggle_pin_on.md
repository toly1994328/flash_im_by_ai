# POST /conversations/eb8cf7ec-44d8-4c38-a190-72bf3c878d81/pin

Toggle 置顶状态（首次调用，取消置顶 → 置顶）。

## Response `200`

```json
{"is_muted":null,"is_pinned":true,"unread_count":null}
```

> 每次调用翻转 is_pinned，置顶时写入 pinned_at 时间戳。