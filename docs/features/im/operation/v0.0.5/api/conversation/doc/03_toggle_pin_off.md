# POST /conversations/eb8cf7ec-44d8-4c38-a190-72bf3c878d81/pin

再次调用翻转置顶状态（置顶 → 取消置顶），pinned_at 清空。

## Response `200`

```json
{"is_muted":null,"is_pinned":false,"unread_count":null}
```

> 每次调用原子翻转，单条 SQL 完成。