# POST /conversations/eb8cf7ec-44d8-4c38-a190-72bf3c878d81/mute

再次调用翻转免打扰状态（开启 → 关闭）。

## Response `200`

```json
{"is_muted":false,"is_pinned":null,"unread_count":null}
```

> 服务端原子翻转，无需客户端传当前状态。