# POST /conversations/eb8cf7ec-44d8-4c38-a190-72bf3c878d81/unread

标记会话为未读，unread_count 固定设为 1。

## Response `200`

```json
{"is_muted":null,"is_pinned":null,"unread_count":1}
```

> 不关心之前有无未读，总是设为 1。同时推送 total_unread 汇总值。